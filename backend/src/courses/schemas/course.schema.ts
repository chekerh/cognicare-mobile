import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type CourseDocument = Course & Document;

@Schema({ timestamps: true })
export class Course {
  @Prop({ required: true })
  title: string;

  @Prop()
  description?: string;

  @Prop({ required: true, unique: true })
  slug: string;

  @Prop({ default: false })
  isQualificationCourse: boolean;

  /** Optional fields for scraped / external training data */
  @Prop()
  startDate?: Date;

  @Prop()
  endDate?: Date;

  @Prop()
  courseType?: string; // e.g. 'basic', 'advanced'

  @Prop()
  price?: string;

  @Prop()
  location?: string;

  @Prop()
  enrollmentLink?: string;

  @Prop()
  certification?: string;

  @Prop()
  targetAudience?: string;

  @Prop()
  prerequisites?: string;

  @Prop()
  sourceUrl?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CourseSchema = SchemaFactory.createForClass(Course);
