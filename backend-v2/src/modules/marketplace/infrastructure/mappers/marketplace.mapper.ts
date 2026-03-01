import { Types } from "mongoose";
import {
  ProductEntity,
  ReviewEntity,
} from "../../domain/entities/marketplace.entity";
import {
  ProductDocument,
  ReviewDocument,
} from "../persistence/mongo/marketplace.schema";

export class ProductMapper {
  static toDomain(doc: ProductDocument): ProductEntity {
    return ProductEntity.reconstitute(doc._id.toString(), {
      sellerId: doc.sellerId?.toString(),
      title: doc.title,
      price: doc.price,
      imageUrl: doc.imageUrl,
      description: doc.description ?? "",
      badge: doc.badge,
      category: doc.category ?? "all",
      order: doc.order ?? 0,
      externalUrl: doc.externalUrl,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: ProductEntity): Record<string, unknown> {
    return {
      sellerId: entity.sellerId ? new Types.ObjectId(entity.sellerId) : null,
      title: entity.title,
      price: entity.price,
      imageUrl: entity.imageUrl,
      description: entity.description,
      badge: entity.badge,
      category: entity.category,
      order: entity.order,
      externalUrl: entity.externalUrl,
    };
  }
}

export class ReviewMapper {
  static toDomain(doc: ReviewDocument): ReviewEntity {
    return ReviewEntity.reconstitute(doc._id.toString(), {
      productId: doc.productId.toString(),
      userId: doc.userId.toString(),
      userName: doc.userName,
      rating: doc.rating,
      comment: doc.comment ?? "",
      userProfileImageUrl: doc.userProfileImageUrl,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: ReviewEntity): Record<string, unknown> {
    return {
      productId: new Types.ObjectId(entity.productId),
      userId: new Types.ObjectId(entity.userId),
      userName: entity.userName,
      rating: entity.rating,
      comment: entity.comment,
      userProfileImageUrl: entity.userProfileImageUrl,
    };
  }
}
