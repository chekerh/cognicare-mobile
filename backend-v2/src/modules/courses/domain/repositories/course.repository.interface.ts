import {
  CourseEntity,
  CourseEnrollmentEntity,
} from "../entities/course.entity";

export interface ICourseRepository {
  findAll(filters?: {
    qualificationOnly?: boolean;
    courseType?: string;
    hasCertification?: boolean;
  }): Promise<CourseEntity[]>;
  findById(id: string): Promise<CourseEntity | null>;
  findBySlug(slug: string): Promise<CourseEntity | null>;
  save(entity: CourseEntity): Promise<CourseEntity>;
}

export interface ICourseEnrollmentRepository {
  findByUserId(userId: string): Promise<CourseEnrollmentEntity[]>;
  findByUserAndCourse(
    userId: string,
    courseId: string,
  ): Promise<CourseEnrollmentEntity | null>;
  findById(id: string): Promise<CourseEnrollmentEntity | null>;
  findAll(userId?: string): Promise<CourseEnrollmentEntity[]>;
  findCompletedByUser(userId: string): Promise<CourseEnrollmentEntity[]>;
  save(entity: CourseEnrollmentEntity): Promise<CourseEnrollmentEntity>;
  update(entity: CourseEnrollmentEntity): Promise<CourseEnrollmentEntity>;
}
