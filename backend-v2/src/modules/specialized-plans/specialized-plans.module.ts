import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { SpecializedPlansService } from "./specialized-plans.service";
import { SpecializedPlansController } from "./specialized-plans.controller";
import {
  SpecializedPlan,
  SpecializedPlanSchema,
} from "./schemas/specialized-plan.schema";
import { ChildSchema } from "@/modules/children/infrastructure/persistence/mongo/child.schema";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SpecializedPlan.name, schema: SpecializedPlanSchema },
      { name: "Child", schema: ChildSchema },
    ]),
  ],
  providers: [SpecializedPlansService],
  controllers: [SpecializedPlansController],
  exports: [SpecializedPlansService],
})
export class SpecializedPlansModule {}
