import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type RecommendationFeedbackDocument = RecommendationFeedback & Document;

@Schema({ timestamps: true })
export class RecommendationFeedback {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'SpecializedPlan' })
  planId?: Types.ObjectId;

  @Prop()
  planType?: string;

  @Prop({ required: true })
  recommendationId!: string;

  @Prop({ required: true, enum: ['approved', 'modified', 'dismissed'] })
  action!: 'approved' | 'modified' | 'dismissed';

  @Prop()
  editedText?: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  specialistId!: Types.ObjectId;

  @Prop()
  originalRecommendationText?: string;

  @Prop()
  resultsImproved?: boolean;

  /** Whether parent feedback (used in this recommendation) was helpful. */
  @Prop()
  parentFeedbackHelpful?: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const RecommendationFeedbackSchema =
  SchemaFactory.createForClass(RecommendationFeedback);

RecommendationFeedbackSchema.index({ childId: 1, recommendationId: 1 });
RecommendationFeedbackSchema.index({ specialistId: 1 });
