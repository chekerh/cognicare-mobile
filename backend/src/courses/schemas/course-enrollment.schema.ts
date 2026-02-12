import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CourseEnrollmentDocument = CourseEnrollment & Document;

@Schema({ timestamps: true })
export class CourseEnrollment {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Course', required: true })
  courseId: Types.ObjectId;

  @Prop({
    default: 'enrolled',
    enum: ['enrolled', 'in_progress', 'completed'],
  })
  status: 'enrolled' | 'in_progress' | 'completed';

  @Prop({ default: 0 })
  progressPercent: number;

  @Prop()
  completedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CourseEnrollmentSchema =
  SchemaFactory.createForClass(CourseEnrollment);
CourseEnrollmentSchema.index({ userId: 1, courseId: 1 }, { unique: true });
