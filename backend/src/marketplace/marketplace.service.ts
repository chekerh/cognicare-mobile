import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { CreateProductDto } from './dto/create-product.dto';

/** Plain object returned by .lean() (no Mongoose Document methods). */
export type ProductLean = Product & { _id: Types.ObjectId };

@Injectable()
export class MarketplaceService {
  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<ProductDocument>,
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
    const product = await this.productModel
      .findById(id)
      .lean()
      .exec();
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product as ProductLean;
  }
}
