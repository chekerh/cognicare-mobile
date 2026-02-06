import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';

/** Plain object returned by .lean() (no Mongoose Document methods). */
export type ProductLean = Product & { _id: Types.ObjectId };

@Injectable()
export class MarketplaceService {
  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<ProductDocument>,
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

  async seedIfEmpty(): Promise<void> {
    const count = await this.productModel.estimatedDocumentCount().exec();
    if (count > 0) return;

    const products = [
      {
        title: 'Weighted Blanket',
        price: '$45.00',
        imageUrl:
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400',
        description: 'Calming sensory support.',
        badge: 'TOP',
        category: 'sensory',
        order: 0,
      },
      {
        title: 'Noise Cancelling Headphones',
        price: '$129.00',
        imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
        description: 'Reduce auditory overload.',
        badge: 'POPULAR',
        category: 'sensory',
        order: 1,
      },
      {
        title: 'Visual Timer',
        price: '$18.50',
        imageUrl:
          'https://images.unsplash.com/photo-1560869713-72d2c8364444?w=400',
        description: 'Time management aid.',
        category: 'cognitive',
        order: 2,
      },
      {
        title: 'Tactile Learning Blocks',
        price: '$29.99',
        imageUrl:
          'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400',
        description: 'Fine motor and texture.',
        badge: 'SKILL',
        category: 'motor',
        order: 3,
      },
      {
        title: 'Wooden Busy Board',
        price: '$34.50',
        imageUrl:
          'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400',
        description: 'Interactive activities.',
        category: 'motor',
        order: 4,
      },
      {
        title: 'Chewelry Pendant',
        price: '$12.00',
        imageUrl:
          'https://images.unsplash.com/photo-1560869713-72d2c8364444?w=400',
        description: 'Safe oral sensory.',
        category: 'sensory',
        order: 5,
      },
    ];
    await this.productModel.insertMany(products);
  }
}
