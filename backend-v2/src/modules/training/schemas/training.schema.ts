import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";
import {
  ContentSection,
  ContentSectionSchema,
  QuizQuestion,
  QuizQuestionSchema,
} from "./sub-schemas";

export type TrainingCourseDocument = TrainingCourse & Document;

@Schema({ timestamps: true })
export class TrainingCourse {
  @Prop({ required: true }) title!: string;
  @Prop() description?: string;
  @Prop({ type: [ContentSectionSchema], default: [] })
  contentSections!: ContentSection[];
  @Prop() sourceUrl?: string;
  @Prop({ type: [String], default: [] }) topics!: string[];
  @Prop({ type: [QuizQuestionSchema], default: [] }) quiz!: QuizQuestion[];
  @Prop({ default: false }) approved!: boolean;
  @Prop({ default: 0 }) order!: number;
  @Prop({ type: Types.ObjectId, ref: "User" }) approvedBy?: Types.ObjectId;
  @Prop() approvedAt?: Date;
  @Prop() professionalComments?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
export const TrainingCourseSchema =
  SchemaFactory.createForClass(TrainingCourse);
TrainingCourseSchema.index({ approved: 1, order: 1 });

export type TrainingEnrollmentDocument = TrainingEnrollment & Document;

@Schema({ timestamps: true })
export class TrainingEnrollment {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  userId!: Types.ObjectId;
  @Prop({ type: Types.ObjectId, ref: "TrainingCourse", required: true })
  courseId!: Types.ObjectId;
  @Prop({ default: 0 }) progressPercent!: number;
  @Prop({ default: false }) contentCompleted!: boolean;
  @Prop({ default: false }) quizPassed!: boolean;
  @Prop() quizScorePercent?: number;
  @Prop() quizAttempts?: number;
  @Prop() completedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}
export const TrainingEnrollmentSchema =
  SchemaFactory.createForClass(TrainingEnrollment);
TrainingEnrollmentSchema.index({ userId: 1, courseId: 1 }, { unique: true });
