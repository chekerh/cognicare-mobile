import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  IProductRepository,
  IReviewRepository,
} from "../../../domain/repositories/marketplace.repository.interface";
import {
  ProductEntity,
  ReviewEntity,
} from "../../../domain/entities/marketplace.entity";
import {
  ProductMongoSchema,
  ProductDocument,
  ReviewMongoSchema,
  ReviewDocument,
} from "./marketplace.schema";
import { ProductMapper, ReviewMapper } from "../../mappers/marketplace.mapper";

@Injectable()
export class ProductMongoRepository implements IProductRepository {
  constructor(
    @InjectModel(ProductMongoSchema.name)
    private readonly model: Model<ProductDocument>,
  ) {}

  async findById(id: string): Promise<ProductEntity | null> {
    const doc = await this.model.findById(id).exec();
    return doc ? ProductMapper.toDomain(doc) : null;
  }

  async findAll(limit = 20, category?: string): Promise<ProductEntity[]> {
    const filter: Record<string, unknown> = {};
    if (category && category !== "all") filter.category = category;
    const docs = await this.model
      .find(filter)
      .sort({ order: 1, createdAt: -1 })
      .limit(limit)
      .exec();
    return docs.map(ProductMapper.toDomain);
  }

  async findBySellerId(sellerId: string): Promise<ProductEntity[]> {
    const docs = await this.model
      .find({ sellerId: new Types.ObjectId(sellerId) })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ProductMapper.toDomain);
  }

  async save(entity: ProductEntity): Promise<ProductEntity> {
    const data = ProductMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return ProductMapper.toDomain(saved);
  }

  async count(): Promise<number> {
    return this.model.countDocuments().exec();
  }

  async saveMany(entities: ProductEntity[]): Promise<void> {
    const docs = entities.map((e) => ({
      _id: new Types.ObjectId(e.id),
      ...ProductMapper.toPersistence(e),
    }));
    await this.model.insertMany(docs);
  }
}

@Injectable()
export class ReviewMongoRepository implements IReviewRepository {
  constructor(
    @InjectModel(ReviewMongoSchema.name)
    private readonly model: Model<ReviewDocument>,
  ) {}

  async findByProductId(productId: string): Promise<ReviewEntity[]> {
    const docs = await this.model
      .find({ productId: new Types.ObjectId(productId) })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ReviewMapper.toDomain);
  }

  async findByProductAndUser(
    productId: string,
    userId: string,
  ): Promise<ReviewEntity | null> {
    const doc = await this.model
      .findOne({
        productId: new Types.ObjectId(productId),
        userId: new Types.ObjectId(userId),
      })
      .exec();
    return doc ? ReviewMapper.toDomain(doc) : null;
  }

  async save(entity: ReviewEntity): Promise<ReviewEntity> {
    const data = ReviewMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return ReviewMapper.toDomain(saved);
  }

  async update(entity: ReviewEntity): Promise<void> {
    const data = ReviewMapper.toPersistence(entity);
    await this.model.findByIdAndUpdate(entity.id, { $set: data }).exec();
  }
}
