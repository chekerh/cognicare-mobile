import { Schema, Types } from 'mongoose';

export const CourseMongoSchema = new Schema(
  {
    title: { type: String, required: true },
    description: String,
    slug: { type: String, required: true, unique: true },
    isQualificationCourse: { type: Boolean, default: false },
    startDate: Date, endDate: Date,
    courseType: String, price: String, location: String,
    enrollmentLink: String, certification: String,
    targetAudience: String, prerequisites: String, sourceUrl: String,
  },
  { timestamps: true },
);

export const CourseEnrollmentMongoSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    courseId: { type: Types.ObjectId, ref: 'Course', required: true },
    status: { type: String, default: 'enrolled', enum: ['enrolled', 'in_progress', 'completed'] },
    progressPercent: { type: Number, default: 0 },
    completedAt: Date,
  },
  { timestamps: true },
);
CourseEnrollmentMongoSchema.index({ userId: 1, courseId: 1 }, { unique: true });
