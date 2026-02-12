import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type BadgeDocument = Badge & Document;

export enum BadgeType {
  GAMES_COMPLETED = 'games_completed',
  POINTS_MILESTONE = 'points_milestone',
  STREAK = 'streak',
  GAME_SPECIFIC = 'game_specific',
  WEEKLY_CHALLENGE = 'weekly_challenge',
}

@Schema({ timestamps: true })
export class Badge {
  @Prop({ required: true, unique: true })
  badgeId: string; // e.g. "first_game", "points_100", "streak_7"

  @Prop({ required: true })
  name: string; // Display name

  @Prop()
  description?: string;

  @Prop({ enum: BadgeType, required: true })
  type: BadgeType;

  @Prop()
  iconUrl?: string; // URL to badge icon/image

  @Prop({ type: Map, of: Number, default: {} })
  requirements: Map<string, number>; // e.g. { "gamesCompleted": 1 }, { "totalPoints": 100 }

  @Prop({ default: true })
  isActive: boolean; // Can be disabled for future badges
}

export const BadgeSchema = SchemaFactory.createForClass(Badge);
