import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import {
  ContentSection,
  ContentSectionSchema,
} from './content-section.schema';
import {
  QuizQuestion,
  QuizQuestionSchema,
} from './quiz-question.schema';

export type TrainingCourseDocument = TrainingCourse & Document;

@Schema({ timestamps: true })
export class TrainingCourse {
  @Prop({ required: true })
  title: string;

  @Prop()
  description?: string;

  @Prop({ type: [ContentSectionSchema], default: [] })
  contentSections: ContentSection[];

  @Prop()
  sourceUrl?: string;

  @Prop({ type: [String], default: [] })
  topics: string[];

  @Prop({ type: [QuizQuestionSchema], default: [] })
  quiz: QuizQuestion[];

  /** Must be validated by professionals before visible in app */
  @Prop({ default: false })
  approved: boolean;

  /** Display order (1 = first course, 2 = second, etc.) */
  @Prop({ default: 0 })
  order: number;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  approvedBy?: Types.ObjectId;

  @Prop()
  approvedAt?: Date;

  @Prop()
  professionalComments?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const TrainingCourseSchema =
  SchemaFactory.createForClass(TrainingCourse);
TrainingCourseSchema.index({ approved: 1, order: 1 });
