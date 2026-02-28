import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VolunteersController } from './volunteers.controller';
import { VolunteersService } from './volunteers.service';
import {
  VolunteerApplication,
  VolunteerApplicationSchema,
} from './schemas/volunteer-application.schema';
import {
  VolunteerTask,
  VolunteerTaskSchema,
} from './schemas/volunteer-task.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { MailModule } from '../mail/mail.module';
import { CoursesModule } from '../courses/courses.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: VolunteerApplication.name,
        schema: VolunteerApplicationSchema,
      },
      { name: VolunteerTask.name, schema: VolunteerTaskSchema },
      { name: User.name, schema: UserSchema },
    ]),
    CloudinaryModule,
    MailModule,
    CoursesModule,
    NotificationsModule,
  ],
  controllers: [VolunteersController],
  providers: [VolunteersService],
  exports: [VolunteersService],
})
export class VolunteersModule {}
