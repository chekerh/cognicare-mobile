import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CourseMongoSchema, CourseEnrollmentMongoSchema } from './infrastructure/persistence/mongo/course.schema';
import { CourseMongoRepository, CourseEnrollmentMongoRepository } from './infrastructure/persistence/mongo/course.mongo-repository';
import {
  COURSE_REPOSITORY_TOKEN, COURSE_ENROLLMENT_REPOSITORY_TOKEN,
  CreateCourseUseCase, ListCoursesUseCase, EnrollCourseUseCase,
  MyEnrollmentsUseCase, ListEnrollmentsForAdminUseCase, UpdateProgressUseCase,
  HasCompletedQualificationCourseUseCase,
} from './application/use-cases/course.use-cases';
import { CoursesController } from './interface/http/courses.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'Course', schema: CourseMongoSchema },
      { name: 'CourseEnrollment', schema: CourseEnrollmentMongoSchema },
    ]),
  ],
  controllers: [CoursesController],
  providers: [
    { provide: COURSE_REPOSITORY_TOKEN, useClass: CourseMongoRepository },
    { provide: COURSE_ENROLLMENT_REPOSITORY_TOKEN, useClass: CourseEnrollmentMongoRepository },
    CreateCourseUseCase, ListCoursesUseCase, EnrollCourseUseCase,
    MyEnrollmentsUseCase, ListEnrollmentsForAdminUseCase, UpdateProgressUseCase,
    HasCompletedQualificationCourseUseCase,
  ],
  exports: [HasCompletedQualificationCourseUseCase, COURSE_REPOSITORY_TOKEN],
})
export class CoursesModule {}
