import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PendingOrganizationDocument = PendingOrganization & Document;

@Schema({ timestamps: true })
export class PendingOrganization {
  @Prop({ required: true })
  organizationName!: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requestedBy!: Types.ObjectId;

  @Prop({ required: true })
  leaderEmail!: string;

  @Prop({ required: true })
  leaderFullName!: string;

  @Prop()
  description?: string;

  @Prop()
  certificateUrl?: string;

  @Prop({
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  })
  status!: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  reviewedBy?: Types.ObjectId;

  @Prop()
  reviewedAt?: Date;

  @Prop()
  rejectionReason?: string;

  @Prop({ type: Types.ObjectId, ref: 'Organization' })
  organizationId?: Types.ObjectId;
}

export const PendingOrganizationSchema =
  SchemaFactory.createForClass(PendingOrganization);

// Index for faster queries
PendingOrganizationSchema.index({ status: 1, createdAt: -1 });
PendingOrganizationSchema.index({ requestedBy: 1 });
