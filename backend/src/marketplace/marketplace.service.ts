import {
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { Review, ReviewDocument } from './schemas/review.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateReviewDto } from './dto/create-review.dto';

/** Catalogue de produits : vêtements, jeux, produits cognitifs (sensoriel, motricité, cognitif) */
const SEED_PRODUCTS = [
  // Vêtements (clothing)
  {
    title: 'Veste sensorielle adaptable',
    price: '45',
    imageUrl: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400',
    description: 'Vêtement apaisant pour hypersensibilité sensorielle, adapté aux troubles du spectre autistique.',
    category: 'clothing',
    badge: 'Adapté TSA',
  },
  {
    title: 'Pull lesté thérapeutique',
    price: '65',
    imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400',
    description: 'Pression profonde pour calmer l\'anxiété et améliorer la concentration. Idéal pour TDAH.',
    category: 'clothing',
    badge: 'TDAH',
  },
  {
    title: 'Pyjama à compression douce',
    price: '38',
    imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400',
    description: 'Confort nocturne pour enfants avec difficultés d\'endormissement.',
    category: 'clothing',
  },
  // Jeux (games)
  {
    title: 'Set de jeux de mémoire cognitive',
    price: '29',
    imageUrl: 'https://images.unsplash.com/photo-1611195974226-ef7b4610e667?w=400',
    description: 'Cartes et activités pour stimuler la mémoire de travail et l\'attention.',
    category: 'games',
    badge: 'Top',
  },
  {
    title: 'Puzzle sensoriel tactiles',
    price: '34',
    imageUrl: 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400',
    description: 'Formes et textures variées pour développer la motricité fine et la coordination.',
    category: 'games',
  },
  {
    title: 'Jeu de tri et classement',
    price: '24',
    imageUrl: 'https://images.unsplash.com/photo-1513542789411-b6d5d1f1b0ff?w=400',
    description: 'Exercices de catégorisation pour renforcer les fonctions exécutives.',
    category: 'games',
    badge: 'Cognitif',
  },
  // Sensoriel (sensory)
  {
    title: 'Couvre-lit lesté',
    price: '89',
    imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400',
    description: 'Réduit l\'anxiété et améliore le sommeil. Pression profonde scientifiquement validée.',
    category: 'sensory',
    badge: 'Populaire',
  },
  {
    title: 'Kits de fidgets sensoriels',
    price: '18',
    imageUrl: 'https://images.unsplash.com/photo-1606312619070-d48b4d17a8b8?w=400',
    description: 'Balles anti-stress, anneaux, briques pour auto-régulation.',
    category: 'sensory',
  },
  {
    title: 'Lampe de poche à fibre optique',
    price: '42',
    imageUrl: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400',
    description: 'Stimulation visuelle apaisante pour les hypersensibilités.',
    category: 'sensory',
  },
  // Motricité (motor)
  {
    title: 'Planche d\'équilibre',
    price: '55',
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400',
    description: 'Développe la coordination et le tonus musculaire.',
    category: 'motor',
  },
  {
    title: 'Tunnel de motricité',
    price: '35',
    imageUrl: 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400',
    description: 'Parfait pour le travail de la motricité globale et le retour au calme.',
    category: 'motor',
  },
  {
    title: 'Set de crayons ergonomiques',
    price: '15',
    imageUrl: 'https://images.unsplash.com/photo-1513542789411-b6d5d1f1b0ff?w=400',
    description: 'Prise en main facilitée pour l\'écriture et le coloriage.',
    category: 'motor',
  },
  // Cognitif (cognitive)
  {
    title: 'Cahier d\'exercices cognitifs',
    price: '22',
    imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
    description: 'Activités pour attention, mémoire et fonctions exécutives.',
    category: 'cognitive',
  },
  {
    title: 'Timer visuel digital',
    price: '28',
    imageUrl: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=400',
    description: 'Gestion du temps et transitions facilitées pour enfants TSA/TDAH.',
    category: 'cognitive',
    badge: 'Recommandé',
  },
  {
    title: 'Planificateur quotidien magnétique',
    price: '32',
    imageUrl: 'https://images.unsplash.com/photo-1507925921958-8a62f3d1a50d?w=400',
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
        this.logger.log('Seeding marketplace catalog (vêtements, jeux, produits cognitifs)...');
        await this.productModel.insertMany(
          SEED_PRODUCTS.map((p, i) => ({
            sellerId: null,
            title: p.title,
            price: p.price,
            imageUrl: p.imageUrl,
            description: p.description ?? '',
            badge: p.badge,
            category: p.category,
            order: i,
          })),
        );
        this.logger.log(`Seeded ${SEED_PRODUCTS.length} marketplace products.`);
      }
    } catch (e) {
      this.logger.warn(`Marketplace seed failed: ${(e as Error).message}`);
    }
  }

  async list(limit = 20, category?: string): Promise<ProductLean[]> {
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
