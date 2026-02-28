import {
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import axios from 'axios';
import { Product, ProductDocument } from './schemas/product.schema';
import { Review, ReviewDocument } from './schemas/review.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateReviewDto } from './dto/create-review.dto';

const DUMMYJSON_BASE = 'https://dummyjson.com';

const TERRAVITA_BASE = 'https://www.terravita.fr';

/** Produits Terravita réels - compléments alimentaires. Acheter = redirection vers Terravita (commande réelle). */
const TERRAVITA_PRODUCTS: Array<{
  title: string;
  price: string;
  imageUrl: string;
  description: string;
  category: string;
  badge?: string;
  externalUrl: string;
}> = [
  {
    title: 'Multivitamines complex',
    price: '18,90',
    imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    description: 'Immunité, vitalité, antioxydant.',
    category: 'supplements',
    badge: 'Meilleure vente',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
  {
    title: 'Magnésium bisglycinate 1500mg',
    price: '13,90',
    imageUrl: 'https://images.unsplash.com/photo-1550572017-edd951aa6b2e?w=400',
    description: 'Anti-stress, sommeil, vitalité.',
    category: 'supplements',
    badge: 'Meilleure vente',
    externalUrl: `${TERRAVITA_BASE}/collections/stress-sommeil`,
  },
  {
    title: 'Oméga 3 EPAX®',
    price: '14,90',
    imageUrl:
      'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
    description: 'Vitalité, mémoire, cœur.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
  {
    title: 'Probiotiques 8 souches',
    price: '17,90',
    imageUrl:
      'https://images.unsplash.com/photo-1584305574647-0cc94953bb1b?w=400',
    description: 'Digestion, immunité, ballonnements.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
  {
    title: 'Vitamine D3',
    price: '9,90',
    imageUrl: 'https://images.unsplash.com/photo-1550572017-edd951aa6b2e?w=400',
    description: 'Immunité, vitalité.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
  {
    title: 'Ashwagandha Bio',
    price: '19,90',
    imageUrl:
      'https://images.unsplash.com/photo-1599909533486-1c36d6d48305?w=400',
    description: 'Anti-stress, mémoire, vitalité.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/stress-sommeil`,
  },
  {
    title: 'Complexe Acide Hyaluronique',
    price: '24,90',
    imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400',
    description: 'Antioxydant, anti-âge, hydratation.',
    category: 'supplements',
    badge: 'Meilleure vente',
    externalUrl: `${TERRAVITA_BASE}/collections/femme`,
  },
  {
    title: 'Collagène marin',
    price: '24,90',
    imageUrl:
      'https://images.unsplash.com/photo-1599909533486-1c36d6d48305?w=400',
    description: 'Articulations, anti-âge, mobilité.',
    category: 'supplements',
    badge: 'Meilleure vente',
    externalUrl: `${TERRAVITA_BASE}/collections/femme`,
  },
  {
    title: 'Lactobacillus gasseri 200 milliards',
    price: '9,90',
    imageUrl:
      'https://images.unsplash.com/photo-1584305574647-0cc94953bb1b?w=400',
    description: 'Minceur, transit, ballonnements.',
    category: 'supplements',
    badge: 'Meilleure vente',
    externalUrl: `${TERRAVITA_BASE}/collections/all`,
  },
  {
    title: 'Vitamine C liposomale',
    price: '22,90',
    imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    description: 'Immunité, vitalité.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
  {
    title: 'Rhodiola',
    price: '18,90',
    imageUrl:
      'https://images.unsplash.com/photo-1599909533486-1c36d6d48305?w=400',
    description: 'Anti-stress, vitalité, résistance.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/stress-sommeil`,
  },
  {
    title: 'Zinc bisglycinate',
    price: '12,90',
    imageUrl: 'https://images.unsplash.com/photo-1550572017-edd951aa6b2e?w=400',
    description: 'Immunité, imperfections.',
    category: 'supplements',
    externalUrl: `${TERRAVITA_BASE}/collections/immunite-vitalite`,
  },
];

/** Mapping catégories : supplements = Terravita (réel). DummyJSON pour vêtements/jeux. Cognitif/sensoriel/moteur = CogniCare. */
const CATEGORY_TO_DUMMYJSON: Record<string, string[] | null> = {
  all: [],
  supplements: null, // Terravita - compléments alimentaires réels
  clothing: [
    'tops',
    'womens-dresses',
    'mens-shirts',
    'womens-shoes',
    'mens-shoes',
    'womens-bags',
  ],
  games: ['sports-accessories', 'mobile-accessories'],
  sensory: null,
  motor: null,
  cognitive: null,
};

/** Catalogue de fallback (si API indisponible) : vêtements, jeux, produits cognitifs */
const SEED_PRODUCTS = [
  // Vêtements (clothing)
  {
    title: 'Veste sensorielle adaptable',
    price: '45',
    imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400',
    description:
      'Vêtement apaisant pour hypersensibilité sensorielle, adapté aux troubles du spectre autistique.',
    category: 'clothing',
    badge: 'Adapté TSA',
  },
  {
    title: 'Pull lesté thérapeutique',
    price: '65',
    imageUrl:
      'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
    description:
      "Pression profonde pour calmer l'anxiété et améliorer la concentration. Idéal pour TDAH.",
    category: 'clothing',
    badge: 'TDAH',
  },
  {
    title: 'Pyjama à compression douce',
    price: '38',
    imageUrl:
      'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400',
    description:
      "Confort nocturne pour enfants avec difficultés d'endormissement.",
    category: 'clothing',
  },
  // Jeux (games)
  {
    title: 'Set de jeux de mémoire cognitive',
    price: '29',
    imageUrl:
      'https://images.unsplash.com/photo-1611195974226-ef7b4610e667?w=400',
    description:
      "Cartes et activités pour stimuler la mémoire de travail et l'attention.",
    category: 'games',
    badge: 'Top',
  },
  {
    title: 'Puzzle sensoriel tactiles',
    price: '34',
    imageUrl:
      'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400',
    description:
      'Formes et textures variées pour développer la motricité fine et la coordination.',
    category: 'games',
  },
  {
    title: 'Jeu de tri et classement',
    price: '24',
    imageUrl:
      'https://images.unsplash.com/photo-1513542789411-b6d5d1f1b0ff?w=400',
    description:
      'Exercices de catégorisation pour renforcer les fonctions exécutives.',
    category: 'games',
    badge: 'Cognitif',
  },
  // Sensoriel (sensory)
  {
    title: 'Couvre-lit lesté',
    price: '89',
    imageUrl:
      'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400',
    description:
      "Réduit l'anxiété et améliore le sommeil. Pression profonde scientifiquement validée.",
    category: 'sensory',
    badge: 'Populaire',
  },
  {
    title: 'Kits de fidgets sensoriels',
    price: '18',
    imageUrl:
      'https://images.unsplash.com/photo-1606312619070-d48b4d17a8b8?w=400',
    description: 'Balles anti-stress, anneaux, briques pour auto-régulation.',
    category: 'sensory',
  },
  {
    title: 'Lampe de poche à fibre optique',
    price: '42',
    imageUrl:
      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400',
    description: 'Stimulation visuelle apaisante pour les hypersensibilités.',
    category: 'sensory',
  },
  // Motricité (motor)
  {
    title: "Planche d'équilibre",
    price: '55',
    imageUrl:
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400',
    description: 'Développe la coordination et le tonus musculaire.',
    category: 'motor',
  },
  {
    title: 'Tunnel de motricité',
    price: '35',
    imageUrl:
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400',
    description:
      'Parfait pour le travail de la motricité globale et le retour au calme.',
    category: 'motor',
  },
  {
    title: 'Set de crayons ergonomiques',
    price: '15',
    imageUrl:
      'https://images.unsplash.com/photo-1513542789411-b6d5d1f1b0ff?w=400',
    description: "Prise en main facilitée pour l'écriture et le coloriage.",
    category: 'motor',
  },
  // Cognitif (cognitive)
  {
    title: "Cahier d'exercices cognitifs",
    price: '22',
    imageUrl:
      'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
    description: 'Activités pour attention, mémoire et fonctions exécutives.',
    category: 'cognitive',
  },
  {
    title: 'Timer visuel digital',
    price: '28',
    imageUrl:
      'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400',
    description:
      'Gestion du temps et transitions facilitées pour enfants TSA/TDAH.',
    category: 'cognitive',
    badge: 'Recommandé',
  },
  {
    title: 'Planificateur quotidien magnétique',
    price: '32',
    imageUrl:
      'https://images.unsplash.com/photo-1507925921958-8a62f3d1a50d?w=400',
    description: 'Organisation visuelle des routines et tâches quotidiennes.',
    category: 'cognitive',
  },
];

/** Plain object returned by .lean() (no Mongoose Document methods). */
export type ProductLean = Product & { _id: Types.ObjectId };
export type ReviewLean = Review & { _id: Types.ObjectId };

@Injectable()
export class MarketplaceService implements OnModuleInit {
  private readonly logger = new Logger(MarketplaceService.name);

  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<ProductDocument>,
    @InjectModel(Review.name)
    private readonly reviewModel: Model<ReviewDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async onModuleInit() {
    try {
      const count = await this.productModel.countDocuments().exec();
      if (count === 0) {
        this.logger.log(
          'Seeding marketplace catalog (vêtements, jeux, cognitifs, compléments Terravita)...',
        );
        const seedItems = [
          ...SEED_PRODUCTS.map((p, i) => ({
            sellerId: null,
            title: p.title,
            price: p.price,
            imageUrl: p.imageUrl,
            description: p.description ?? '',
            badge: p.badge,
            category: p.category,
            order: i,
            externalUrl: undefined,
          })),
          ...TERRAVITA_PRODUCTS.map((p, i) => ({
            sellerId: null,
            title: p.title,
            price: p.price,
            imageUrl: p.imageUrl,
            description: p.description ?? '',
            badge: p.badge,
            category: p.category,
            order: SEED_PRODUCTS.length + i,
            externalUrl: p.externalUrl,
          })),
        ];
        await this.productModel.insertMany(seedItems);
        this.logger.log(
          `Seeded ${seedItems.length} products (dont ${TERRAVITA_PRODUCTS.length} Terravita).`,
        );
      } else {
        const supplementsCount = await this.productModel
          .countDocuments({ category: 'supplements' })
          .exec();
        if (supplementsCount === 0) {
          this.logger.log(
            'Adding Terravita supplements to existing catalog...',
          );
          await this.productModel.insertMany(
            TERRAVITA_PRODUCTS.map((p, i) => ({
              sellerId: null,
              title: p.title,
              price: p.price,
              imageUrl: p.imageUrl,
              description: p.description ?? '',
              badge: p.badge,
              category: p.category,
              order: count + i,
              externalUrl: p.externalUrl,
            })),
          );
          this.logger.log(
            `Added ${TERRAVITA_PRODUCTS.length} Terravita products.`,
          );
        }
      }
    } catch (e) {
      this.logger.warn(`Marketplace seed failed: ${(e as Error).message}`);
    }
  }

  /**
   * Récupère les produits : DummyJSON (vêtements, jeux) ou catalogue CogniCare (cognitif, sensoriel, motricité).
   */
  async list(limit = 20, category?: string): Promise<ProductLean[]> {
    const cat = category && category !== 'all' ? category : 'all';
    const dummyCategories = CATEGORY_TO_DUMMYJSON[cat];

    // Cognitif, Sensoriel, Motricité : catalogue CogniCare (produits adaptés, pas des PC)
    if (dummyCategories === null) {
      return this.listFromDb(limit, cat);
    }

    try {
      let products: Record<string, unknown>[] = [];

      if (dummyCategories.length === 0) {
        const res = await axios.get<{ products: Record<string, unknown>[] }>(
          `${DUMMYJSON_BASE}/products`,
          { params: { limit }, timeout: 8000 },
        );
        products = res.data?.products ?? [];
      } else {
        const perCat = Math.ceil(limit / dummyCategories.length);
        const results = await Promise.all(
          dummyCategories.map((dc) =>
            axios.get<{ products: Record<string, unknown>[] }>(
              `${DUMMYJSON_BASE}/products/category/${dc}`,
              { params: { limit: perCat }, timeout: 8000 },
            ),
          ),
        );
        products = results.flatMap((r) => r.data?.products ?? []);
        products = products.slice(0, limit);
      }

      return products.map((p) => this.toProductLean(p, cat));
    } catch (e) {
      this.logger.warn(
        `DummyJSON API failed: ${(e as Error).message}, using fallback`,
      );
      return this.listFromDb(limit, cat);
    }
  }

  private toProductLean(
    raw: Record<string, unknown>,
    category: string,
  ): ProductLean {
    const images = raw.images as string[] | undefined;
    const imageUrl =
      (raw.imageUrl as string) ??
      images?.[0] ??
      (raw.thumbnail as string) ??
      '';
    const price = raw.price != null ? String(raw.price) : '0';
    const discount = raw.discountPercentage as number | undefined;
    const badge =
      discount != null && discount > 0
        ? `-${Math.round(discount)}%`
        : undefined;
    const id = raw.id != null ? String(raw.id) : '';
    return {
      _id: id as unknown as Types.ObjectId,
      sellerId: undefined,
      title: (raw.title ?? '') as string,
      price,
      imageUrl,
      description: (raw.description ?? '') as string,
      badge,
      category,
      order: 0,
      externalUrl: undefined,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as ProductLean;
  }

  private async listFromDb(
    limit: number,
    category: string,
  ): Promise<ProductLean[]> {
    const q: Record<string, unknown> = {};
    if (category && category !== 'all') q.category = category;
    const list = await this.productModel
      .find(q)
      .sort({ order: 1, createdAt: -1 })
      .limit(limit)
      .lean()
      .exec();
    return list as ProductLean[];
  }

  /** Liste uniquement les produits créés par l'utilisateur connecté. */
  async listBySeller(
    userId: string,
    limit = 50,
    category?: string,
  ): Promise<ProductLean[]> {
    const q: Record<string, unknown> = {
      sellerId: new Types.ObjectId(userId),
    };
    if (category && category !== 'all') q.category = category;
    const list = await this.productModel
      .find(q)
      .sort({ order: 1, createdAt: -1 })
      .limit(limit)
      .lean()
      .exec();
    return list as ProductLean[];
  }

  async uploadProductImage(file: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<string> {
    if (this.cloudinary.isConfigured()) {
      const crypto = await import('crypto');
      const publicId = `product-${crypto.randomUUID()}`;
      return this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/marketplace',
        publicId,
      });
    }
    const path = await import('path');
    const fs = await import('fs/promises');
    const crypto = await import('crypto');
    const uploadsDir = path.join(process.cwd(), 'uploads', 'marketplace');
    await fs.mkdir(uploadsDir, { recursive: true });
    const m = file.mimetype ?? '';
    const ext =
      m === 'image/png'
        ? 'png'
        : m === 'image/webp'
          ? 'webp'
          : m === 'image/heic'
            ? 'heic'
            : 'jpg';
    const id = crypto.randomUUID();
    const filename = `${id}.${ext}`;
    const filePath = path.join(uploadsDir, filename);
    await fs.writeFile(filePath, file.buffer);
    return `/uploads/marketplace/${filename}`;
  }

  async create(userId: string, dto: CreateProductDto): Promise<ProductLean> {
    const product = await this.productModel.create({
      sellerId: new Types.ObjectId(userId),
      title: dto.title,
      price: dto.price,
      imageUrl: dto.imageUrl,
      description: dto.description ?? '',
      badge: dto.badge ?? undefined,
      category: dto.category ?? 'all',
      order: dto.order ?? 0,
    });
    return product.toObject() as ProductLean;
  }

  async findById(id: string): Promise<ProductLean> {
    // ID numérique = produit DummyJSON (API externe)
    const numId = parseInt(id, 10);
    if (!Number.isNaN(numId) && numId > 0 && numId < 1000) {
      try {
        const res = await axios.get<Record<string, unknown>>(
          `${DUMMYJSON_BASE}/products/${numId}`,
          { timeout: 5000 },
        );
        const raw = res.data;
        if (raw?.id != null) {
          const cat = (raw.category as string) ?? 'all';
          return this.toProductLean(raw, cat);
        }
      } catch {
        // ignore, fall through to DB
      }
    }

    // ID MongoDB
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException('Product not found');
    }
    const product = await this.productModel.findById(id).lean().exec();
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product as ProductLean;
  }

  async listReviews(productId: string): Promise<ReviewLean[]> {
    if (!Types.ObjectId.isValid(productId)) return [];
    const list = await this.reviewModel
      .find({ productId: new Types.ObjectId(productId) })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
    return list as ReviewLean[];
  }

  async createOrUpdateReview(
    productId: string,
    userId: string,
    dto: CreateReviewDto,
  ): Promise<ReviewLean> {
    if (!Types.ObjectId.isValid(productId)) {
      throw new NotFoundException('Product not found');
    }
    const product = await this.productModel.findById(productId).exec();
    if (!product) throw new NotFoundException('Product not found');

    const user = await this.userModel
      .findById(userId)
      .select('fullName profilePic')
      .lean()
      .exec();
    const userName = user?.fullName ?? 'User';
    const userProfileImageUrl = user?.profilePic ?? undefined;

    const review = await this.reviewModel.findOneAndUpdate(
      {
        productId: new Types.ObjectId(productId),
        userId: new Types.ObjectId(userId),
      },
      {
        $set: {
          rating: dto.rating,
          comment: dto.comment ?? '',
          userName,
          ...(userProfileImageUrl != null &&
            userProfileImageUrl !== '' && { userProfileImageUrl }),
          updatedAt: new Date(),
        },
      },
      { upsert: true, new: true },
    );
    return review.toObject() as ReviewLean;
  }
}
