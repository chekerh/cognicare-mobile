import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type IntegrationOrderDocument = IntegrationOrder & Document;

@Schema({ timestamps: true })
export class IntegrationOrder {
  @Prop({ type: Types.ObjectId, ref: 'ExternalWebsite', required: true })
  websiteId: Types.ObjectId;

  @Prop({ required: true })
  externalId: string;

  @Prop({ default: '' })
  productName: string;

  @Prop({ default: 1 })
  quantity: number;

  @Prop({ type: Object, default: {} })
  formData: Record<string, string>;

  @Prop({ default: 'pending' })
  status: string;

  @Prop({ default: null })
  sentToSiteAt?: Date;

  @Prop({ default: '' })
  externalOrderId?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const IntegrationOrderSchema =
  SchemaFactory.createForClass(IntegrationOrder);

IntegrationOrderSchema.index({ websiteId: 1, createdAt: -1 });
