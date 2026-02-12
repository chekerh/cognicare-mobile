import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type InvitationDocument = Invitation & Document;

@Schema({ timestamps: true })
export class Invitation {
  @Prop({ type: Types.ObjectId, ref: 'Organization', required: true })
  organizationId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId;

  @Prop({ required: true })
  userEmail!: string;

  @Prop({ required: true })
  organizationName!: string;

  @Prop({ required: true, enum: ['staff', 'family'] })
  invitationType!: 'staff' | 'family';

  @Prop({ required: true, enum: ['pending', 'accepted', 'rejected'], default: 'pending' })
  status!: 'pending' | 'accepted' | 'rejected';

  @Prop({ required: true })
  token!: string;

  @Prop()
  expiresAt!: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const InvitationSchema = SchemaFactory.createForClass(Invitation);

// Index for token lookup
InvitationSchema.index({ token: 1 });

// Index for cleanup of expired invitations
InvitationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
