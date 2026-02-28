import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Course } from './schemas/course.schema';
import { CourseEnrollment } from './schemas/course-enrollment.schema';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class CoursesService {
  constructor(
    @InjectModel(Course.name) private readonly courseModel: Model<Course>,
    @InjectModel(CourseEnrollment.name)
    private readonly enrollmentModel: Model<CourseEnrollment>,
    private readonly notifications: NotificationsService,
  ) {}

  async create(dto: {
    title: string;
    description?: string;
    slug: string;
    isQualificationCourse?: boolean;
    startDate?: Date;
    endDate?: Date;
    courseType?: string;
    price?: string;
    location?: string;
    enrollmentLink?: string;
    certification?: string;
    targetAudience?: string;
    prerequisites?: string;
    sourceUrl?: string;
  }) {
    const existing = await this.courseModel.findOne({ slug: dto.slug }).exec();
    if (existing) {
      return this.findAll();
    }
    await this.courseModel.create(dto);
    return this.findAll();
  }

  async findAll(filters?: {
    qualificationOnly?: boolean;
    courseType?: string;
    hasCertification?: boolean;
  }) {
    const query: Record<string, unknown> = {};
    if (filters?.qualificationOnly === true) query.isQualificationCourse = true;
    if (filters?.courseType) query.courseType = filters.courseType;
    if (filters?.hasCertification === true) {
      query.certification = { $exists: true, $nin: [null, ''] };
    }
    const list = await this.courseModel
      .find(query)
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    return list.map((c) => {
      const r = c as Record<string, unknown>;
      return {
        id: r._id?.toString?.(),
        title: r.title,
        description: r.description,
        slug: r.slug,
        isQualificationCourse: r.isQualificationCourse,
        startDate: r.startDate,
        endDate: r.endDate,
        courseType: r.courseType,
        price: r.price,
        location: r.location,
        enrollmentLink: r.enrollmentLink,
        certification: r.certification,
        targetAudience: r.targetAudience,
        prerequisites: r.prerequisites,
      };
    });
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
        user: user ? { fullName: user.fullName, email: user.email } : null,
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
    const wasCompleted =
      enrollment.status === 'completed' && enrollment.progressPercent >= 100;
    enrollment.progressPercent = Math.min(100, Math.max(0, progressPercent));
    if (enrollment.progressPercent >= 100) {
      enrollment.status = 'completed';
      enrollment.completedAt = new Date();
    } else {
      enrollment.status = 'in_progress';
    }
    await enrollment.save();
    if (
      enrollment.progressPercent >= 100 &&
      enrollment.status === 'completed' &&
      !wasCompleted
    ) {
      const course = await this.courseModel
        .findById(enrollment.courseId)
        .lean()
        .exec();
      const isQualification = (course as Record<string, unknown>)
        ?.isQualificationCourse;
      if (isQualification) {
        await this.notifications.createForUser(userId, {
          type: 'volunteer_training_complete',
          title: 'Formation qualifiante terminée',
          description:
            'Passez le test de certification pour débloquer l\'Agenda et les Messages.',
          data: {
            courseId: (enrollment.courseId as Types.ObjectId)?.toString?.(),
          },
        });
      }
    }
    return this.myEnrollments(userId);
  }

  /**
   * Returns true if the user has at least one completed enrollment in a qualification course.
   */
  async hasCompletedQualificationCourse(userId: string): Promise<boolean> {
    const list = await this.enrollmentModel
      .find({
        userId: new Types.ObjectId(userId),
        status: 'completed',
        progressPercent: 100,
      })
      .populate('courseId', 'isQualificationCourse')
      .lean()
      .exec();
    for (const e of list) {
      const course = (e as Record<string, unknown>).courseId as {
        isQualificationCourse?: boolean;
      } | null;
      if (course?.isQualificationCourse) return true;
    }
    return false;
  }
}
