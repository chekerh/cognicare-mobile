import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DonationMongoSchema } from './infrastructure/persistence/mongo/donation.schema';
import { DonationMongoRepository } from './infrastructure/persistence/mongo/donation.mongo-repository';
import {
  DONATION_REPOSITORY_TOKEN, CreateDonationUseCase, ListDonationsUseCase, UploadDonationImageUseCase,
} from './application/use-cases/donation.use-cases';
import { DonationsController } from './interface/http/donations.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: 'Donation', schema: DonationMongoSchema }]),
  ],
  controllers: [DonationsController],
  providers: [
    { provide: DONATION_REPOSITORY_TOKEN, useClass: DonationMongoRepository },
    CreateDonationUseCase, ListDonationsUseCase, UploadDonationImageUseCase,
  ],
  exports: [DONATION_REPOSITORY_TOKEN],
})
export class DonationsModule {}
