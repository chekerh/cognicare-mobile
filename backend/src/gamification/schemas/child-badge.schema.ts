import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ChildBadgeDocument = ChildBadge & Document;

@Schema({ timestamps: true })
export class ChildBadge {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Badge', required: true })
  badgeId: Types.ObjectId;

  @Prop({ required: true })
  badgeIdString: string; // Denormalized for quick lookup

  @Prop({ default: Date.now })
  earnedAt: Date;

  @Prop()
  gameType?: string; // Which game unlocked it (if applicable)
}

export const ChildBadgeSchema = SchemaFactory.createForClass(ChildBadge);
ChildBadgeSchema.index({ childId: 1, badgeIdString: 1 }, { unique: true });
