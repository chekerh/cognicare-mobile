import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProductDocument = Product & Document;

@Schema({ timestamps: true })
export class Product {
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  sellerId?: Types.ObjectId;

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

  /** URL du site partenaire (ex: Terravita) - si présente, "Acheter" redirige vers ce site pour commande réelle */
  @Prop({ default: null })
  externalUrl?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
