import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  CertificationTest,
  CertificationTestSchema,
} from './schemas/certification-test.schema';
import {
  CertificationAttempt,
  CertificationAttemptSchema,
} from './schemas/certification-attempt.schema';
import { CertificationTestService } from './certification-test.service';
import { CertificationTestController } from './certification-test.controller';
import { VolunteersModule } from '../volunteers/volunteers.module';
import { CoursesModule } from '../courses/courses.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CertificationTest.name, schema: CertificationTestSchema },
      { name: CertificationAttempt.name, schema: CertificationAttemptSchema },
    ]),
    VolunteersModule,
    CoursesModule,
  ],
  controllers: [CertificationTestController],
  providers: [CertificationTestService],
  exports: [CertificationTestService],
})
export class CertificationTestModule {}
