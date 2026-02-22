import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ParentFeedbackDocument = ParentFeedback & Document;

@Schema({ timestamps: true })
export class ParentFeedback {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  parentId!: Types.ObjectId;

  @Prop({ required: true, min: 1, max: 5 })
  rating!: number;

  @Prop()
  comment?: string;

  @Prop()
  planType?: string; // Optional: PECS, TEACCH, SkillTracker, Activity

  createdAt?: Date;
  updatedAt?: Date;
}

export const ParentFeedbackSchema = SchemaFactory.createForClass(ParentFeedback);

ParentFeedbackSchema.index({ childId: 1, parentId: 1, createdAt: -1 });
ParentFeedbackSchema.index({ childId: 1, createdAt: -1 });
