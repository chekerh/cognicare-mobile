import { Types } from 'mongoose';
import { CourseEntity, CourseEnrollmentEntity } from '../../domain/entities/course.entity';

export class CourseMapper {
  static toDomain(raw: Record<string, any>): CourseEntity {
    return CourseEntity.reconstitute(raw._id.toString(), {
      title: raw.title, description: raw.description, slug: raw.slug,
      isQualificationCourse: raw.isQualificationCourse ?? false,
      startDate: raw.startDate, endDate: raw.endDate,
      courseType: raw.courseType, price: raw.price, location: raw.location,
      enrollmentLink: raw.enrollmentLink, certification: raw.certification,
      targetAudience: raw.targetAudience, prerequisites: raw.prerequisites,
      sourceUrl: raw.sourceUrl, createdAt: raw.createdAt,
    });
  }
  static toPersistence(e: CourseEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id), title: e.title, description: e.description,
      slug: e.slug, isQualificationCourse: e.isQualificationCourse,
      startDate: e.startDate, endDate: e.endDate, courseType: e.courseType,
      price: e.price, location: e.location, enrollmentLink: e.enrollmentLink,
      certification: e.certification, targetAudience: e.targetAudience,
      prerequisites: e.prerequisites,
    };
  }
}

export class CourseEnrollmentMapper {
  static toDomain(raw: Record<string, any>): CourseEnrollmentEntity {
    return CourseEnrollmentEntity.reconstitute(raw._id.toString(), {
      userId: raw.userId?.toString() ?? '',
      courseId: raw.courseId?.toString() ?? '',
      status: raw.status ?? 'enrolled',
      progressPercent: raw.progressPercent ?? 0,
      completedAt: raw.completedAt,
      updatedAt: raw.updatedAt,
    });
  }
  static toPersistence(e: CourseEnrollmentEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id),
      userId: new Types.ObjectId(e.userId),
      courseId: new Types.ObjectId(e.courseId),
      status: e.status,
      progressPercent: e.progressPercent,
      completedAt: e.completedAt,
    };
  }
}
