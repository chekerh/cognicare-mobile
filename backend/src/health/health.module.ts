import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { MongooseModule } from '@nestjs/mongoose';
import { HealthController } from './health.controller';
import { MedicationVerificationService } from './medication-verification.service';

@Module({
  imports: [TerminusModule, MongooseModule],
  controllers: [HealthController],
  providers: [MedicationVerificationService],
  exports: [MedicationVerificationService],
})
export class HealthModule {}
