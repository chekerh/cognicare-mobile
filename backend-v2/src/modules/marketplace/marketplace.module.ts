import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  ProductMongoSchema,
  ProductSchema,
  ReviewMongoSchema,
  ReviewSchema,
} from "./infrastructure/persistence/mongo/marketplace.schema";
import {
  PRODUCT_REPOSITORY_TOKEN,
  REVIEW_REPOSITORY_TOKEN,
} from "./domain/repositories/marketplace.repository.interface";
import {
  ProductMongoRepository,
  ReviewMongoRepository,
} from "./infrastructure/persistence/mongo/marketplace.mongo-repository";
import {
  ListProductsUseCase,
  ListProductsBySellerUseCase,
  GetProductByIdUseCase,
  CreateProductUseCase,
  ListReviewsUseCase,
  CreateOrUpdateReviewUseCase,
  UploadProductImageUseCase,
  SeedProductsService,
} from "./application/use-cases/marketplace.use-cases";
import { MarketplaceController } from "./interface/http/marketplace.controller";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ProductMongoSchema.name, schema: ProductSchema },
      { name: ReviewMongoSchema.name, schema: ReviewSchema },
    ]),
  ],
  controllers: [MarketplaceController],
  providers: [
    { provide: PRODUCT_REPOSITORY_TOKEN, useClass: ProductMongoRepository },
    { provide: REVIEW_REPOSITORY_TOKEN, useClass: ReviewMongoRepository },
    ListProductsUseCase,
    ListProductsBySellerUseCase,
    GetProductByIdUseCase,
    CreateProductUseCase,
    ListReviewsUseCase,
    CreateOrUpdateReviewUseCase,
    UploadProductImageUseCase,
    SeedProductsService,
  ],
  exports: [PRODUCT_REPOSITORY_TOKEN],
})
export class MarketplaceModule {}
