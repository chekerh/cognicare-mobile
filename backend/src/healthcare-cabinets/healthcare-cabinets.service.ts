import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  HealthcareCabinet,
  HealthcareCabinetDocument,
} from './schemas/healthcare-cabinet.schema';

/** Cabinets et centres en Tunisie (maladies cognitives, autisme, orthophonie, etc.) — données réelles ou représentatives. */
const SEED_CABINETS: Array<{
  name: string;
  specialty: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  phone?: string;
  website?: string;
}> = [
  {
    name: 'Cabinet Dr. Zayneb Zouch - Orthophoniste',
    specialty: 'Orthophoniste',
    address: 'Route de Tunis km 6, Immeuble Ennakhla, 1er étage, Sfax',
    city: 'Sfax',
    latitude: 34.7406,
    longitude: 10.7603,
    phone: '+216 20 671 867',
  },
  {
    name: 'Cabinet Yasmine Zaghbani - Orthophoniste',
    specialty: 'Orthophoniste',
    address: '24 rue Habib Bourguiba, Centre médical Ibn Rochd, 1er étage',
    city: 'Hammam Lif',
    latitude: 36.7333,
    longitude: 10.3333,
    phone: '28 160 380',
  },
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
  {
    name: 'Cabinet Psychologue Enfant - Les Berges du Lac',
    specialty: 'Psychologue',
    address: 'Les Berges du Lac, Tunis',
    city: 'Tunis',
    latitude: 36.8333,
    longitude: 10.25,
  },
  {
    name: 'Centre d\'Accueil et d\'Orientation - Sousse',
    specialty: 'Centre multidisciplinaire',
    address: 'Avenue Habib Bourguiba, Sousse',
    city: 'Sousse',
    latitude: 35.8256,
    longitude: 10.6346,
  },
  {
    name: 'Cabinet Ergothérapie - Sfax',
    specialty: 'Ergothérapeute',
    address: 'Route de la Plage, Sfax',
    city: 'Sfax',
    latitude: 34.735,
    longitude: 10.758,
  },
  {
    name: 'Association Tunisienne de l\'Autisme - Siège',
    specialty: 'Association / Ressources',
    address: 'Tunis',
    city: 'Tunis',
    latitude: 36.7989,
    longitude: 10.1656,
  },
  {
    name: 'Centre de Santé Mentale Infantile - Nabeul',
    specialty: 'Pédopsychiatrie',
    address: 'Nabeul',
    city: 'Nabeul',
    latitude: 36.4561,
    longitude: 10.7376,
  },
  {
    name: 'Cabinet Orthophonie - Monastir',
    specialty: 'Orthophoniste',
    address: 'Avenue de l\'Environnement, Monastir',
    city: 'Monastir',
    latitude: 35.7772,
    longitude: 10.8261,
  },
  {
    name: 'Unité TSA - Hôpital Charles Nicolle',
    specialty: 'Pédopsychiatrie / TSA',
    address: 'Boulevard du 9 Avril, Tunis',
    city: 'Tunis',
    latitude: 36.8144,
    longitude: 10.0839,
  },
  {
    name: 'Cabinet Psychologue - Sousse Médina',
    specialty: 'Psychologue',
    address: 'Sousse Médina',
    city: 'Sousse',
    latitude: 35.8272,
    longitude: 10.6342,
  },
];

@Injectable()
export class HealthcareCabinetsService implements OnModuleInit {
  private readonly logger = new Logger(HealthcareCabinetsService.name);

  constructor(
    @InjectModel(HealthcareCabinet.name)
    private readonly cabinetModel: Model<HealthcareCabinetDocument>,
  ) {}

  async onModuleInit() {
    try {
      const count = await this.cabinetModel.countDocuments().exec();
      if (count === 0) {
        this.logger.log(
          'Seeding healthcare cabinets (Tunisia — orthophonistes, pédopsychiatres, centres)...',
        );
        await this.cabinetModel.insertMany(SEED_CABINETS);
        this.logger.log(`Seeded ${SEED_CABINETS.length} healthcare cabinets.`);
      }
    } catch (e) {
      this.logger.warn(
        `Healthcare cabinets seed failed: ${(e as Error).message}`,
      );
    }
  }

  async findAll(): Promise<HealthcareCabinet[]> {
    return this.cabinetModel.find().sort({ city: 1, name: 1 }).lean().exec();
  }
}
