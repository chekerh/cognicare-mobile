import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ProductDocument = ProductMongoSchema & Document;

@Schema({ timestamps: true, collection: "products" })
export class ProductMongoSchema {
  @Prop({ type: Types.ObjectId, ref: "User", default: null })
  sellerId?: Types.ObjectId;

  @Prop({ required: true })
  title!: string;

  @Prop({ required: true })
  price!: string;

  @Prop({ required: true })
  imageUrl!: string;

  @Prop({ default: "" })
  description!: string;

  @Prop({ default: null })
  badge?: string;

  @Prop({ default: "all" })
  category!: string;

  @Prop({ default: 0 })
  order!: number;

  @Prop({ default: null })
  externalUrl?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ProductSchema = SchemaFactory.createForClass(ProductMongoSchema);

export type ReviewDocument = ReviewMongoSchema & Document;

@Schema({ timestamps: true, collection: "reviews" })
export class ReviewMongoSchema {
  @Prop({ type: Types.ObjectId, ref: "Product", required: true })
  productId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  userId!: Types.ObjectId;

  @Prop({ required: true })
  userName!: string;

  @Prop({ required: true, min: 1, max: 5 })
  rating!: number;

  @Prop({ default: "" })
  comment!: string;

  @Prop({ default: null })
  userProfileImageUrl?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ReviewSchema = SchemaFactory.createForClass(ReviewMongoSchema);
ReviewSchema.index({ productId: 1, userId: 1 }, { unique: true });
