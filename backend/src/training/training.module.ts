import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TrainingCourse, TrainingCourseSchema } from './schemas/training-course.schema';
import {
  TrainingEnrollment,
  TrainingEnrollmentSchema,
} from './schemas/training-enrollment.schema';
import { TrainingController } from './training.controller';
import { TrainingService } from './training.service';
import { TrainingSeedRunner } from './training-seed.runner';
import { VolunteersModule } from '../volunteers/volunteers.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TrainingCourse.name, schema: TrainingCourseSchema },
      { name: TrainingEnrollment.name, schema: TrainingEnrollmentSchema },
    ]),
    forwardRef(() => VolunteersModule),
  ],
  controllers: [TrainingController],
  providers: [TrainingService, TrainingSeedRunner],
  exports: [TrainingService],
})
export class TrainingModule {}
