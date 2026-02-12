import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import {
  VolunteerDocument,
  VolunteerDocumentSchema,
} from './volunteer-document.schema';

export type VolunteerApplicationDocument = VolunteerApplication & Document;

@Schema({ timestamps: true })
export class VolunteerApplication {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, unique: true })
  userId: Types.ObjectId;

  /** pending | approved | denied */
  @Prop({ required: true, default: 'pending', enum: ['pending', 'approved', 'denied'] })
  status: 'pending' | 'approved' | 'denied';

  @Prop({ type: [VolunteerDocumentSchema], default: [] })
  documents: VolunteerDocument[];

  @Prop()
  deniedReason?: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  reviewedBy?: Types.ObjectId;

  @Prop()
  reviewedAt?: Date;

  @Prop({ default: false })
  denialNotificationSent?: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const VolunteerApplicationSchema = SchemaFactory.createForClass(
  VolunteerApplication,
);
VolunteerApplicationSchema.index({ userId: 1 });
VolunteerApplicationSchema.index({ status: 1 });
