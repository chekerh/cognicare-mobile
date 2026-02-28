import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import axios from 'axios';
import { Model } from 'mongoose';
import {
  HealthcareCabinet,
  HealthcareCabinetDocument,
} from './schemas/healthcare-cabinet.schema';

/**
 * Source des cabinets : OpenStreetMap (Overpass API), gratuit, sans clé.
 * Aucun Google Cloud requis.
 */

/** Bbox Tunisie (sud, ouest, nord, est) pour Overpass. */
const TUNISIA_BBOX = [32.3, 8.1, 37.3, 11.3];
const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';

/** Requête Overpass : établissements de santé en Tunisie (hôpitaux, cliniques, cabinets, etc.). */
const OVERPASS_QUERY = `
[out:json][timeout:60];
(
  node["amenity"~"hospital|clinic|doctors|dentist"](${TUNISIA_BBOX.join(',')});
  way["amenity"~"hospital|clinic|doctors|dentist"](${TUNISIA_BBOX.join(',')});
  node["healthcare"](${TUNISIA_BBOX.join(',')});
  way["healthcare"](${TUNISIA_BBOX.join(',')});
);
out center;
`;

interface OverpassElement {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

interface OverpassResponse {
  elements?: OverpassElement[];
}

@Injectable()
export class HealthcareCabinetsService implements OnModuleInit {
  private readonly logger = new Logger(HealthcareCabinetsService.name);

  constructor(
    @InjectModel(HealthcareCabinet.name)
    private readonly cabinetModel: Model<HealthcareCabinetDocument>,
  ) {}

  async onModuleInit() {
    const count = await this.cabinetModel.countDocuments().exec();
    if (count === 0) {
      this.logger.log(
        'Aucun cabinet en base — chargement depuis OpenStreetMap (Tunisie)...',
      );
      try {
        await this.fetchFromOverpassAndUpsert();
      } catch (e) {
        this.logger.warn(
          `Overpass échoué: ${(e as Error).message}. Seed minimal.`,
        );
        await this.seedIfEmpty();
      }
    } else {
      this.logger.log(`${count} cabinet(s) en base.`);
    }
  }

  private async seedIfEmpty() {
    const count = await this.cabinetModel.countDocuments().exec();
    if (count > 0) return;
    const minimalSeed = [
      {
        name: 'Centre de Rééducation du Langage - Tunis',
        specialty: 'Orthophoniste',
        address: 'Avenue de la Liberté, Tunis',
        city: 'Tunis',
        latitude: 36.8065,
        longitude: 10.1815,
      },
      {
        name: 'Unité de Pédopsychiatrie - Hôpital Razi',
        specialty: 'Pédopsychiatrie',
        address: 'La Manouba, Tunis',
        city: 'Tunis',
        latitude: 36.8092,
        longitude: 10.0956,
      },
    ];
    await this.cabinetModel.insertMany(minimalSeed);
    this.logger.log(`Seed minimal: ${minimalSeed.length} cabinets.`);
  }

  /**
   * Récupère les établissements de santé en Tunisie via Overpass API (OpenStreetMap)
   * et les enregistre en base. Aucune clé API requise.
   */
  async fetchFromOverpassAndUpsert(): Promise<{ added: number; total: number }> {
    const response = await axios.post<OverpassResponse>(
      OVERPASS_URL,
      new URLSearchParams({ data: OVERPASS_QUERY }).toString(),
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 90000,
      },
    );

    const elements = response.data?.elements ?? [];
    let added = 0;

    for (const el of elements) {
      const lat = el.lat ?? el.center?.lat;
      const lon = el.lon ?? el.center?.lon;
      if (lat == null || lon == null) continue;

      const name =
        el.tags?.name ??
        el.tags?.['addr:street'] ??
        `Établissement de santé ${el.type}/${el.id}`;
      const address = this.formatAddress(el.tags);
      const city =
        el.tags?.['addr:city'] ??
        el.tags?.['addr:place'] ??
        el.tags?.['addr:suburb'] ??
        'Tunisie';
      const specialty = this.specialtyFromOsmTags(el.tags);
      const placeId = `osm_${el.type}_${el.id}`;

      const doc: Partial<HealthcareCabinet> = {
        placeId,
        name,
        specialty,
        address,
        city,
        latitude: lat,
        longitude: lon,
        phone: el.tags?.phone ?? el.tags?.['contact:phone'] ?? undefined,
        website: el.tags?.website ?? el.tags?.['contact:website'] ?? undefined,
      };

      const updated = await this.cabinetModel
        .findOneAndUpdate({ placeId }, { $set: doc }, { upsert: true, new: true })
        .exec();
      if (updated) added++;
    }

    const total = await this.cabinetModel.countDocuments().exec();
    this.logger.log(
      `OpenStreetMap refresh: ${added} nouveau(x), total ${total} cabinet(s).`,
    );
    return { added, total };
  }

  private formatAddress(tags?: Record<string, string>): string {
    if (!tags) return '';
    const parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:place'],
      tags['addr:city'],
      tags['addr:postcode'],
    ].filter(Boolean);
    return parts.join(', ') || tags['address'] || '';
  }

  private specialtyFromOsmTags(tags?: Record<string, string>): string {
    if (!tags) return 'Cabinet / Centre';
    const a = (tags['amenity'] ?? '').toLowerCase();
    const h = (tags['healthcare'] ?? '').toLowerCase();
    const spec = (tags['healthcare:speciality'] ?? '').toLowerCase();
    if (a.includes('hospital') || h.includes('hospital')) return 'Hôpital';
    if (a.includes('clinic') || h.includes('clinic')) return 'Clinique';
    if (a.includes('doctors')) return 'Cabinet médical';
    if (a.includes('dentist')) return 'Dentiste';
    if (spec) return spec;
    if (h) return h;
    return 'Cabinet / Centre';
  }

  async findAll(): Promise<HealthcareCabinet[]> {
    return this.cabinetModel.find().sort({ city: 1, name: 1 }).lean().exec();
  }
}
