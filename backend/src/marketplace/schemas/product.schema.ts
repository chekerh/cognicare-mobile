import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ProductDocument = Product & Document;

@Schema({ timestamps: true })
export class Product {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  price: string;

  @Prop({ required: true })
  imageUrl: string;

  @Prop({ default: '' })
  description: string;

  @Prop({ default: null })
  badge?: string;

  @Prop({ default: 'all' })
  category: string; // all | sensory | motor | cognitive

  @Prop({ default: 0 })
  order: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
