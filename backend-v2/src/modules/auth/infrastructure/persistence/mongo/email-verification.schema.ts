/**
 * Email Verification Mongoose Schema - Infrastructure Layer
 */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type EmailVerificationDocument = EmailVerificationMongoSchema & Document;

@Schema({ timestamps: true, collection: 'email_verifications' })
export class EmailVerificationMongoSchema {
  @Prop({ required: true, lowercase: true, trim: true })
  email!: string;

  @Prop({ required: true })
  codeHash!: string;

  @Prop({ required: true })
  expiresAt!: Date;

  createdAt?: Date;
}

export const EmailVerificationSchema = SchemaFactory.createForClass(EmailVerificationMongoSchema);

// TTL index - auto-delete after expiration
EmailVerificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
EmailVerificationSchema.index({ email: 1 });
