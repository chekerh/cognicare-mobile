import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ExternalProductDocument = ExternalProduct & Document;

@Schema({ timestamps: true })
export class ExternalProduct {
  @Prop({ type: Types.ObjectId, ref: 'ExternalWebsite', required: true })
  websiteId: Types.ObjectId;

  @Prop({ required: true })
  externalId: string; // id on the source site (e.g. book slug)

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  price: string;

  @Prop({ default: true })
  availability: boolean;

  @Prop({ default: '' })
  description: string;

  @Prop({ type: [String], default: [] })
  imageUrls: string[];

  @Prop({ default: '' })
  category: string;

  @Prop({ default: '' })
  productUrl: string;

  @Prop({ default: null })
  lastScrapedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ExternalProductSchema = SchemaFactory.createForClass(ExternalProduct);

ExternalProductSchema.index({ websiteId: 1, externalId: 1 }, { unique: true });
ExternalProductSchema.index({ websiteId: 1, category: 1 });
