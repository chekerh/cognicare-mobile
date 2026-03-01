/**
 * User Mongoose Schema - Infrastructure Layer
 */
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type UserDocument = UserMongoSchema & Document;

@Schema({ timestamps: true, collection: 'users' })
export class UserMongoSchema {
  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email!: string;

  @Prop({ required: true })
  passwordHash!: string;

  @Prop({
    required: true,
    enum: [
      'family', 'doctor', 'volunteer', 'admin', 'organization_leader',
      'psychologist', 'speech_therapist', 'occupational_therapist', 'other'
    ],
  })
  role!: string;

  @Prop()
  firstName?: string;

  @Prop()
  lastName?: string;

  @Prop()
  phone?: string;

  @Prop()
  profileImageUrl?: string;

  @Prop({ type: Types.ObjectId, ref: 'Organization' })
  organizationId?: Types.ObjectId;

  @Prop({ default: false })
  isEmailVerified!: boolean;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  blockedUserIds?: Types.ObjectId[];

  @Prop()
  refreshTokenHash?: string;

  @Prop()
  deletedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(UserMongoSchema);

// Indexes
UserSchema.index({ email: 1 }, { unique: true });
UserSchema.index({ role: 1 });
UserSchema.index({ organizationId: 1 });
UserSchema.index({ deletedAt: 1 });
