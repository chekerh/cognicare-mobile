import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  HealthcareCabinet,
  HealthcareCabinetSchema,
} from "./schemas/healthcare-cabinet.schema";
import { HealthcareCabinetsService } from "./healthcare-cabinets.service";
import { HealthcareCabinetsController } from "./healthcare-cabinets.controller";

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
