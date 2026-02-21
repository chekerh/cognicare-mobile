import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  fullName!: string;

  @Prop({ required: true, unique: true })
  email!: string;

  @Prop()
  phone?: string;

  @Prop({ required: true })
  passwordHash!: string;

  @Prop({
    required: true,
    index: true,
    enum: [
      'family',
      'doctor',
      'volunteer',
      'admin',
      'organization_leader',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ],
  })
  role!:
    | 'family'
    | 'doctor'
    | 'volunteer'
    | 'admin'
    | 'organization_leader'
    | 'psychologist'
    | 'speech_therapist'
    | 'occupational_therapist'
    | 'other';

  @Prop({ type: 'ObjectId', ref: 'Organization' })
  organizationId?: string;

  @Prop({ type: 'ObjectId', ref: 'User' })
  specialistId?: string;

  @Prop()
  profilePic?: string;

  @Prop()
  refreshToken?: string;

  @Prop()
  passwordResetCode?: string;

  @Prop()
  passwordResetExpires?: Date;

  @Prop()
  emailChangeCode?: string;

  @Prop()
  emailChangeExpires?: Date;

  @Prop()
  pendingEmail?: string;

  /** Last time the user was active (login or presence ping). Used for "online" status. */
  @Prop()
  lastSeenAt?: Date;

  /** User IDs that this user has blocked (no messages, no new conversation). */
  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  blockedUserIds?: Types.ObjectId[];

  @Prop({ default: true })
  isConfirmed!: boolean;

  @Prop()
  confirmationToken?: string;

  /** Metadata for tracking who added the user (for families/staff) */
  @Prop({ type: 'ObjectId', ref: 'Organization' })
  addedByOrganizationId?: string;

  @Prop({ type: 'ObjectId', ref: 'User' })
  addedBySpecialistId?: string;

  @Prop({ type: 'ObjectId', ref: 'User' })
  lastModifiedBy?: string;

  /** Timestamp for soft delete */
  @Prop()
  deletedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ role: 1, fullName: 1 });
