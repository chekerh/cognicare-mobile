import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TrainingEnrollmentDocument = TrainingEnrollment & Document;

@Schema({ timestamps: true })
export class TrainingEnrollment {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'TrainingCourse', required: true })
  courseId: Types.ObjectId;

  @Prop({ default: 0 })
  progressPercent: number;

  @Prop({ default: false })
  contentCompleted: boolean;

  @Prop({ default: false })
  quizPassed: boolean;

  @Prop()
  quizScorePercent?: number;

  @Prop()
  quizAttempts?: number;

  @Prop()
  completedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const TrainingEnrollmentSchema =
  SchemaFactory.createForClass(TrainingEnrollment);
TrainingEnrollmentSchema.index({ userId: 1, courseId: 1 }, { unique: true });
