import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VolunteersController } from './volunteers.controller';
import { VolunteersService } from './volunteers.service';
import {
  VolunteerApplication,
  VolunteerApplicationSchema,
} from './schemas/volunteer-application.schema';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { MailModule } from '../mail/mail.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: VolunteerApplication.name,
        schema: VolunteerApplicationSchema,
      },
    ]),
    CloudinaryModule,
    MailModule,
  ],
  controllers: [VolunteersController],
  providers: [VolunteersService],
  exports: [VolunteersService],
})
export class VolunteersModule {}
