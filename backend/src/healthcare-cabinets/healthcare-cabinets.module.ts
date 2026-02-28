import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  HealthcareCabinet,
  HealthcareCabinetSchema,
} from './schemas/healthcare-cabinet.schema';
import { HealthcareCabinetsController } from './healthcare-cabinets.controller';
import { HealthcareCabinetsService } from './healthcare-cabinets.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HealthcareCabinet.name, schema: HealthcareCabinetSchema },
    ]),
  ],
  controllers: [HealthcareCabinetsController],
  providers: [HealthcareCabinetsService],
  exports: [HealthcareCabinetsService],
})
export class HealthcareCabinetsModule {}
