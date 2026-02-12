import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PointsDocument = Points & Document;

@Schema({ timestamps: true })
export class Points {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId: Types.ObjectId;

  @Prop({ default: 0 })
  totalPoints: number;

  @Prop({ type: Map, of: Number, default: {} })
  pointsByGame: Map<string, number>; // e.g. { "matching": 150, "star_tracer": 200 }

  @Prop({ type: [String], default: [] })
  gamesPlayed: string[]; // List of game types played

  @Prop({ default: 0 })
  gamesCompleted: number; // Total games won

  @Prop({ default: 0 })
  currentStreak: number; // Days in a row playing

  @Prop()
  lastPlayedDate?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const PointsSchema = SchemaFactory.createForClass(Points);
PointsSchema.index({ childId: 1 }, { unique: true });
