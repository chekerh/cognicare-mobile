import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { Review, ReviewDocument } from './schemas/review.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateReviewDto } from './dto/create-review.dto';

/** Plain object returned by .lean() (no Mongoose Document methods). */
export type ProductLean = Product & { _id: Types.ObjectId };
export type ReviewLean = Review & { _id: Types.ObjectId };

@Injectable()
export class MarketplaceService {
  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<ProductDocument>,
    @InjectModel(Review.name)
    private readonly reviewModel: Model<ReviewDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    private readonly cloudinary: CloudinaryService,
  ) {}

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
