import { ProductEntity, ReviewEntity } from '../entities/marketplace.entity';

export const PRODUCT_REPOSITORY_TOKEN = Symbol('IProductRepository');
export const REVIEW_REPOSITORY_TOKEN = Symbol('IReviewRepository');

export interface IProductRepository {
  findById(id: string): Promise<ProductEntity | null>;
  findAll(limit?: number, category?: string): Promise<ProductEntity[]>;
  findBySellerId(sellerId: string): Promise<ProductEntity[]>;
  save(entity: ProductEntity): Promise<ProductEntity>;
  count(): Promise<number>;
  saveMany(entities: ProductEntity[]): Promise<void>;
}

export interface IReviewRepository {
  findByProductId(productId: string): Promise<ReviewEntity[]>;
  findByProductAndUser(productId: string, userId: string): Promise<ReviewEntity | null>;
  save(entity: ReviewEntity): Promise<ReviewEntity>;
  update(entity: ReviewEntity): Promise<void>;
}
