import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type FollowRequestDocument = FollowRequest & Document;

export type FollowRequestStatus = 'pending' | 'accepted' | 'declined';

@Schema({ timestamps: true })
export class FollowRequest {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requesterId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  targetId: Types.ObjectId;

  @Prop({ enum: ['pending', 'accepted', 'declined'], default: 'pending' })
  status: FollowRequestStatus;

  createdAt?: Date;
  updatedAt?: Date;
}

export const FollowRequestSchema = SchemaFactory.createForClass(FollowRequest);
FollowRequestSchema.index({ requesterId: 1, targetId: 1 }, { unique: true });
FollowRequestSchema.index({ targetId: 1, status: 1 });
FollowRequestSchema.index({ requesterId: 1, targetId: 1, status: 1 });
