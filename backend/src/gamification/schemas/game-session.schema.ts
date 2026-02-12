import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type GameSessionDocument = GameSession & Document;

export enum GameType {
  MATCHING = 'matching',
  SHAPE_SORTING = 'shape_sorting',
  STAR_TRACER = 'star_tracer',
  BASKET_SORT = 'basket_sort',
}

@Schema({ timestamps: true })
export class GameSession {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId: Types.ObjectId;

  @Prop({ enum: GameType, required: true })
  gameType: GameType;

  @Prop()
  level?: number; // Level within the game (if applicable)

  @Prop({ default: false })
  completed: boolean; // Did the child complete/win?

  @Prop({ default: 0 })
  score: number; // Points earned in this session

  @Prop({ default: 0 })
  timeSpentSeconds: number; // How long they played

  @Prop({ type: Map, of: Number, default: {} })
  metrics: Map<string, number>; // e.g. { "matches": 8, "errors": 2 }

  createdAt?: Date;
  updatedAt?: Date;
}

export const GameSessionSchema = SchemaFactory.createForClass(GameSession);
GameSessionSchema.index({ childId: 1, createdAt: -1 });
GameSessionSchema.index({ childId: 1, gameType: 1, createdAt: -1 });
