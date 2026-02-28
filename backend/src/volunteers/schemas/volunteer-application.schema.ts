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
  @Prop({
    required: true,
    default: 'pending',
    enum: ['pending', 'approved', 'denied'],
  })
  status: 'pending' | 'approved' | 'denied';

  /**
   * Care Provider breakdown: specific role chosen after signup.
   * speech_therapist | occupational_therapist | psychologist | doctor | ergotherapist | caregiver | organization_leader | other
   */
  @Prop({
    enum: [
      'speech_therapist',
      'occupational_therapist',
      'psychologist',
      'doctor',
      'ergotherapist',
      'caregiver',
      'organization_leader',
      'other',
    ],
  })
  careProviderType?:
    | 'speech_therapist'
    | 'occupational_therapist'
    | 'psychologist'
    | 'doctor'
    | 'ergotherapist'
    | 'caregiver'
    | 'organization_leader'
    | 'other';

  /** Optional specialty (e.g. for healthcare providers). */
  @Prop()
  specialty?: string;

  /** For organization leaders: organization name. */
  @Prop()
  organizationName?: string;

  /** For organization leaders: role/title in the organization. */
  @Prop()
  organizationRole?: string;

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

  /** Set when volunteer completes required training and passes the certification test */
  @Prop({ default: false })
  trainingCertified?: boolean;

  @Prop()
  trainingCertifiedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const VolunteerApplicationSchema =
  SchemaFactory.createForClass(VolunteerApplication);
VolunteerApplicationSchema.index({ userId: 1 });
VolunteerApplicationSchema.index({ status: 1 });
