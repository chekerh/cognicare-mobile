import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Course } from './schemas/course.schema';
import { CourseEnrollment } from './schemas/course-enrollment.schema';

@Injectable()
export class CoursesService {
  constructor(
    @InjectModel(Course.name) private readonly courseModel: Model<Course>,
    @InjectModel(CourseEnrollment.name)
    private readonly enrollmentModel: Model<CourseEnrollment>,
  ) {}

  async findAll(qualificationOnly?: boolean) {
    const query: Record<string, unknown> = {};
    if (qualificationOnly === true) query.isQualificationCourse = true;
    const list = await this.courseModel.find(query).sort({ createdAt: 1 }).lean().exec();
    return list.map((c) => ({
      id: (c as Record<string, unknown>)._id?.toString?.(),
      title: (c as Record<string, unknown>).title,
      description: (c as Record<string, unknown>).description,
      slug: (c as Record<string, unknown>).slug,
      isQualificationCourse: (c as Record<string, unknown>).isQualificationCourse,
    }));
  }

  async enroll(userId: string, courseId: string) {
    const course = await this.courseModel.findById(courseId).exec();
    if (!course) throw new NotFoundException('Course not found');
    const existing = await this.enrollmentModel
      .findOne({
        userId: new Types.ObjectId(userId),
        courseId: new Types.ObjectId(courseId),
      })
      .exec();
    if (existing) {
      return this.myEnrollments(userId);
    }
    await this.enrollmentModel.create({
      userId: new Types.ObjectId(userId),
      courseId: new Types.ObjectId(courseId),
      status: 'enrolled',
      progressPercent: 0,
    });
    return this.myEnrollments(userId);
  }

  async myEnrollments(userId: string) {
    const list = await this.enrollmentModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('courseId', 'title slug isQualificationCourse')
      .sort({ updatedAt: -1 })
      .lean()
      .exec();
    return list.map((e) => {
      const o = e as Record<string, unknown>;
      const course = o.courseId as Record<string, unknown> | null;
      return {
        id: (o._id as { toString(): string })?.toString?.(),
        courseId: (o.courseId as Types.ObjectId)?.toString?.(),
        status: o.status,
        progressPercent: o.progressPercent,
        completedAt: o.completedAt,
        course: course
          ? {
              title: course.title,
              slug: course.slug,
              isQualificationCourse: course.isQualificationCourse,
            }
          : null,
      };
    });
  }

  /**
   * Admin: list enrollments, optionally filtered by userId. Used to show volunteer course progress.
   */
  async listEnrollmentsForAdmin(userId?: string) {
    const query: Record<string, unknown> = {};
    if (userId) query.userId = new Types.ObjectId(userId);
    const list = await this.enrollmentModel
      .find(query)
      .populate('userId', 'fullName email')
      .populate('courseId', 'title slug isQualificationCourse')
      .sort({ updatedAt: -1 })
      .lean()
      .exec();
    return list.map((e) => {
      const o = e as Record<string, unknown>;
      const course = o.courseId as Record<string, unknown> | null;
      const user = o.userId as Record<string, unknown> | null;
      return {
        id: (o._id as { toString(): string })?.toString?.(),
        userId: (o.userId as Types.ObjectId)?.toString?.(),
        courseId: (o.courseId as Types.ObjectId)?.toString?.(),
        status: o.status,
        progressPercent: o.progressPercent,
        completedAt: o.completedAt,
        user: user
          ? { fullName: user.fullName, email: user.email }
          : null,
        course: course
          ? {
              title: course.title,
              slug: course.slug,
              isQualificationCourse: course.isQualificationCourse,
            }
          : null,
      };
    });
  }

  async updateProgress(
    userId: string,
    enrollmentId: string,
    progressPercent: number,
  ) {
    const enrollment = await this.enrollmentModel
      .findOne({
        _id: enrollmentId,
        userId: new Types.ObjectId(userId),
      })
      .exec();
    if (!enrollment) throw new NotFoundException('Enrollment not found');
    enrollment.progressPercent = Math.min(100, Math.max(0, progressPercent));
    if (enrollment.progressPercent >= 100) {
      enrollment.status = 'completed';
      enrollment.completedAt = new Date();
    } else {
      enrollment.status = 'in_progress';
    }
    await enrollment.save();
    return this.myEnrollments(userId);
  }
}
