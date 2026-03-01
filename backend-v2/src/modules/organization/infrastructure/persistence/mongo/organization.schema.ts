/**
 * Organization Mongoose Schema - Infrastructure Layer
 */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type OrganizationDocument = OrganizationMongoSchema & Document;

@Schema({ timestamps: true, collection: 'organizations' })
export class OrganizationMongoSchema {
  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  leaderId!: Types.ObjectId;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  staffIds!: Types.ObjectId[];

  @Prop({ type: [Types.ObjectId], ref: 'Child', default: [] })
  childIds!: Types.ObjectId[];

  @Prop()
  certificateUrl?: string;

  @Prop()
  description?: string;

  @Prop()
  address?: string;

  @Prop()
  phone?: string;

  @Prop()
  email?: string;

  @Prop()
  website?: string;

  @Prop({ default: false })
  isApproved!: boolean;

  @Prop()
  approvedAt?: Date;

  @Prop()
  rejectedAt?: Date;

  @Prop()
  rejectionReason?: string;

  @Prop()
  deletedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const OrganizationSchema = SchemaFactory.createForClass(OrganizationMongoSchema);

// Indexes
OrganizationSchema.index({ leaderId: 1 }, { unique: true });
OrganizationSchema.index({ staffIds: 1 });
OrganizationSchema.index({ isApproved: 1 });
OrganizationSchema.index({ deletedAt: 1 });
