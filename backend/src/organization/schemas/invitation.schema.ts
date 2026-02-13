import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type InvitationDocument = Invitation & Document;

@Schema({ timestamps: true })
export class Invitation {
  @Prop({ type: Types.ObjectId, ref: 'Organization', required: false })
  organizationId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false })
  userId?: Types.ObjectId;

  @Prop({ required: false })
  userEmail?: string;

  @Prop({ required: false })
  email?: string; // For org leader invitations

  @Prop({ required: false })
  organizationName?: string;

  @Prop({ required: false, enum: ['staff', 'family', 'org_leader_invite'] })
  invitationType?: 'staff' | 'family' | 'org_leader_invite';

  @Prop({ required: false, enum: ['staff', 'family', 'org_leader_invite'] })
  type?: 'staff' | 'family' | 'org_leader_invite';

  @Prop({
    required: true,
    enum: ['pending', 'accepted', 'rejected', 'expired'],
    default: 'pending',
  })
  status!: 'pending' | 'accepted' | 'rejected' | 'expired';

  @Prop({ required: true })
  token!: string;

  @Prop()
  expiresAt!: Date;

  // Fields for org leader invitation
  @Prop({ required: false })
  leaderFullName?: string;

  @Prop({ required: false })
  leaderPhone?: string;

  @Prop({ required: false })
  leaderPassword?: string; // Hashed password

  createdAt?: Date;
  updatedAt?: Date;
}

export const InvitationSchema = SchemaFactory.createForClass(Invitation);

// Index for token lookup
InvitationSchema.index({ token: 1 });

// Index for cleanup of expired invitations
InvitationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
