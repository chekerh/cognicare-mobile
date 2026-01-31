import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type EmailVerificationDocument = EmailVerification & Document;

@Schema({ timestamps: true })
export class EmailVerification {
  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  code: string;

  @Prop({ required: true })
  expiresAt: Date;

  @Prop({ default: false })
  verified: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const EmailVerificationSchema = SchemaFactory.createForClass(EmailVerification);

// Index to automatically delete expired documents after 15 minutes
EmailVerificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
