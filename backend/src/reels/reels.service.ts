import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import axios from 'axios';
import { Reel, ReelDocument } from './reel.schema';

/** Instances Invidious (gratuit, sans clé). On essaie la première puis les suivantes si échec. */
const INVIDIOUS_INSTANCES = [
  'https://vid.puffyan.us',
  'https://invidious.flokinet.to',
  'https://inv.riverside.rocks',
  'https://invidious.nerdvpn.de',
];

/** Mots-clés pour filtrer le contenu lié aux troubles cognitifs / autisme / aidants. */
const COGNITIVE_KEYWORDS = [
  'autisme',
  'autism',
  'troubles cognitifs',
  'cognitive',
  'sensory',
  'sensoriel',
  'TDAH',
  'ADHD',
  'aidant',
  'caregiver',
  'orthophonie',
  'speech therapy',
  'inclusion',
  'handicap',
  'neurodiversité',
  'neurodiversity',
];

interface InvidiousSearchItem {
  type?: string;
  title?: string;
  videoId?: string;
  description?: string;
  videoThumbnails?: Array<{ quality?: string; url?: string }>;
  published?: number;
  lengthSeconds?: number;
}

@Injectable()
export class ReelsService {
  private readonly logger = new Logger(ReelsService.name);

  constructor(
    @InjectModel(Reel.name) private reelModel: Model<ReelDocument>,
    private config: ConfigService,
  ) {}

  /**
   * Liste les reels pour l'app (paginated).
   */
  async list(page = 1, limit = 20): Promise<{
    reels: Reel[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const skip = (page - 1) * limit;
    const [reels, total] = await Promise.all([
      this.reelModel
        .find()
        .sort({ publishedAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.reelModel.countDocuments().exec(),
    ]);
    return {
      reels: reels as Reel[],
      total,
      page,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  /**
   * Score de pertinence simple par mots-clés (titre + description).
   * Retourne un nombre entre 0 et 1.
   */
  private keywordRelevanceScore(title: string, description: string): number {
    const text = `${(title || '').toLowerCase()} ${(description || '').toLowerCase()}`;
    let hits = 0;
    for (const kw of COGNITIVE_KEYWORDS) {
      if (text.includes(kw.toLowerCase())) hits++;
    }
    if (hits === 0) return 0;
    return Math.min(1, 0.3 + hits * 0.15);
  }

  /**
   * Récupère des shorts via Invidious (scrape, gratuit).
   * Recherche par mots-clés troubles cognitifs / autisme, enregistre en base.
   */
  async refreshFromYoutube(): Promise<{ added: number; skipped: number }> {
    const customBase = this.config.get<string>('INVIDIOUS_BASE_URL');
    const bases = customBase
      ? [customBase.replace(/\/$/, '')]
      : INVIDIOUS_INSTANCES;

    let added = 0;
    let skipped = 0;

    const queries = [
      'autisme',
      'autism sensory',
      'troubles cognitifs',
      'caregiver autism',
      'orthophonie enfant',
      'TDAH enfant',
      'inclusion scolaire',
    ];

    for (const q of queries) {
      let items: InvidiousSearchItem[] = [];
      for (const base of bases) {
        const searchUrl = `${base}/api/v1/search`;
        try {
          const { data } = await axios.get<InvidiousSearchItem[]>(searchUrl, {
            params: {
              q,
              type: 'video',
              duration: 'short',
              sort: 'relevance',
            },
            timeout: 12000,
            validateStatus: () => true,
            headers: {
              'User-Agent': 'CogniCare-Reels/1.0 (Family app)',
              Accept: 'application/json',
            },
          });
          if (typeof data === 'object' && Array.isArray(data)) {
            items = data;
            break;
          }
        } catch (err) {
          this.logger.warn(`Invidious ${base} search "${q}" failed: ${err}`);
          continue;
        }
      }
      // Si aucune instance ne renvoie de shorts, essayer sans filtre durée et garder les courtes (< 90 s).
      if (items.length === 0) {
        for (const base of bases) {
          const searchUrl = `${base}/api/v1/search`;
          try {
            const { data } = await axios.get<InvidiousSearchItem[]>(searchUrl, {
              params: { q, type: 'video', sort: 'relevance' },
              timeout: 12000,
              validateStatus: () => true,
              headers: {
                'User-Agent': 'CogniCare-Reels/1.0 (Family app)',
                Accept: 'application/json',
              },
            });
            if (typeof data === 'object' && Array.isArray(data)) {
              items = data.filter(
                (x) => (x.lengthSeconds ?? 999) <= 90,
              );
              break;
            }
          } catch (err) {
            continue;
          }
        }
      }

      for (const v of items) {
        if (v.type !== 'video' || !v.videoId) continue;
        if ((v.lengthSeconds ?? 0) > 120) continue;
        const videoId = v.videoId;
        const title = v.title || '';
        const description = v.description || '';
        const score = this.keywordRelevanceScore(title, description);
        // Accepter toutes les vidéos des recherches ciblées (la requête filtre déjà le thème).
        const minScore = 0.05;
        if (score < minScore) {
          skipped++;
          continue;
        }

        const existing = await this.reelModel
          .findOne({ source: 'youtube', sourceId: videoId })
          .exec();
        if (existing) {
          skipped++;
          continue;
        }

        const thumb =
          v.videoThumbnails?.find((t) => t.quality === 'medium')?.url ||
          v.videoThumbnails?.[0]?.url ||
          '';
        const videoUrl = `https://www.youtube.com/shorts/${videoId}`;
        const publishedAt = v.published
          ? new Date(v.published * 1000)
          : new Date();

        await this.reelModel.create({
          sourceId: videoId,
          source: 'youtube',
          title,
          description: (description || '').slice(0, 500),
          videoUrl,
          thumbnailUrl: thumb || `https://i.ytimg.com/vi/${videoId}/mqdefault.jpg`,
          publishedAt,
          relevanceScore: score,
          language: 'fr',
        });
        added++;
      }
    }

    this.logger.log(`Reels refresh (Invidious): added=${added}, skipped=${skipped}`);
    return { added, skipped };
  }
}
