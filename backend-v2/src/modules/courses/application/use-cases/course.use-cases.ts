import { Inject, Injectable } from '@nestjs/common';
import { Result, ok, err } from '../../../../core/result';
import { ICourseRepository, ICourseEnrollmentRepository } from '../../domain/repositories/course.repository.interface';
import { CourseEntity, CourseEnrollmentEntity } from '../../domain/entities/course.entity';

export const COURSE_REPOSITORY_TOKEN = Symbol('ICourseRepository');
export const COURSE_ENROLLMENT_REPOSITORY_TOKEN = Symbol('ICourseEnrollmentRepository');

@Injectable()
export class CreateCourseUseCase {
  constructor(@Inject(COURSE_REPOSITORY_TOKEN) private readonly repo: ICourseRepository) {}
  async execute(dto: {
    title: string; description?: string; slug: string; isQualificationCourse?: boolean;
    startDate?: Date; endDate?: Date; courseType?: string; price?: string;
    location?: string; enrollmentLink?: string; certification?: string;
    targetAudience?: string; prerequisites?: string; sourceUrl?: string;
  }): Promise<Result<any[], string>> {
    const existing = await this.repo.findBySlug(dto.slug);
    if (existing) {
      const all = await this.repo.findAll();
      return ok(all.map(c => this.toOutput(c)));
    }
    const entity = CourseEntity.create({ ...dto, isQualificationCourse: dto.isQualificationCourse ?? false });
    await this.repo.save(entity);
    const all = await this.repo.findAll();
    return ok(all.map(c => this.toOutput(c)));
  }
  private toOutput(c: CourseEntity) {
    return { id: c.id, title: c.title, description: c.description, slug: c.slug,
      isQualificationCourse: c.isQualificationCourse, startDate: c.startDate,
      endDate: c.endDate, courseType: c.courseType, price: c.price,
      location: c.location, enrollmentLink: c.enrollmentLink,
      certification: c.certification, targetAudience: c.targetAudience,
      prerequisites: c.prerequisites };
  }
}

@Injectable()
export class ListCoursesUseCase {
  constructor(@Inject(COURSE_REPOSITORY_TOKEN) private readonly repo: ICourseRepository) {}
  async execute(filters?: { qualificationOnly?: boolean; courseType?: string; hasCertification?: boolean }): Promise<Result<any[], string>> {
    const list = await this.repo.findAll(filters);
    return ok(list.map(c => ({ id: c.id, title: c.title, description: c.description,
      slug: c.slug, isQualificationCourse: c.isQualificationCourse,
      startDate: c.startDate, endDate: c.endDate, courseType: c.courseType,
      price: c.price, location: c.location, enrollmentLink: c.enrollmentLink,
      certification: c.certification, targetAudience: c.targetAudience,
      prerequisites: c.prerequisites })));
  }
}

@Injectable()
export class EnrollCourseUseCase {
  constructor(
    @Inject(COURSE_REPOSITORY_TOKEN) private readonly courseRepo: ICourseRepository,
    @Inject(COURSE_ENROLLMENT_REPOSITORY_TOKEN) private readonly enrollRepo: ICourseEnrollmentRepository,
  ) {}
  async execute(userId: string, courseId: string): Promise<Result<any[], string>> {
    const course = await this.courseRepo.findById(courseId);
    if (!course) return err('Course not found');
    const existing = await this.enrollRepo.findByUserAndCourse(userId, courseId);
    if (!existing) {
      const entity = CourseEnrollmentEntity.create(userId, courseId);
      await this.enrollRepo.save(entity);
    }
    return this.getEnrollments(userId);
  }
  private async getEnrollments(userId: string) {
    const list = await this.enrollRepo.findByUserId(userId);
    return ok(list.map(e => ({ id: e.id, courseId: e.courseId, status: e.status, progressPercent: e.progressPercent, completedAt: e.completedAt })));
  }
}

@Injectable()
export class MyEnrollmentsUseCase {
  constructor(@Inject(COURSE_ENROLLMENT_REPOSITORY_TOKEN) private readonly repo: ICourseEnrollmentRepository) {}
  async execute(userId: string): Promise<Result<any[], string>> {
    const list = await this.repo.findByUserId(userId);
    return ok(list.map(e => ({ id: e.id, courseId: e.courseId, status: e.status, progressPercent: e.progressPercent, completedAt: e.completedAt })));
  }
}

@Injectable()
export class ListEnrollmentsForAdminUseCase {
  constructor(@Inject(COURSE_ENROLLMENT_REPOSITORY_TOKEN) private readonly repo: ICourseEnrollmentRepository) {}
  async execute(userId?: string): Promise<Result<any[], string>> {
    const list = await this.repo.findAll(userId);
    return ok(list.map(e => ({ id: e.id, userId: e.userId, courseId: e.courseId, status: e.status, progressPercent: e.progressPercent, completedAt: e.completedAt })));
  }
}

@Injectable()
export class UpdateProgressUseCase {
  constructor(@Inject(COURSE_ENROLLMENT_REPOSITORY_TOKEN) private readonly repo: ICourseEnrollmentRepository) {}
  async execute(userId: string, enrollmentId: string, progressPercent: number): Promise<Result<any[], string>> {
    const enrollment = await this.repo.findById(enrollmentId);
    if (!enrollment || enrollment.userId !== userId) return err('Enrollment not found');
    enrollment.updateProgress(progressPercent);
    await this.repo.update(enrollment);
    const list = await this.repo.findByUserId(userId);
    return ok(list.map(e => ({ id: e.id, courseId: e.courseId, status: e.status, progressPercent: e.progressPercent, completedAt: e.completedAt })));
  }
}

@Injectable()
export class HasCompletedQualificationCourseUseCase {
  constructor(
    @Inject(COURSE_ENROLLMENT_REPOSITORY_TOKEN) private readonly enrollRepo: ICourseEnrollmentRepository,
    @Inject(COURSE_REPOSITORY_TOKEN) private readonly courseRepo: ICourseRepository,
  ) {}
  async execute(userId: string): Promise<boolean> {
    const completed = await this.enrollRepo.findCompletedByUser(userId);
    for (const e of completed) {
      const course = await this.courseRepo.findById(e.courseId);
      if (course?.isQualificationCourse) return true;
    }
    return false;
  }
}
