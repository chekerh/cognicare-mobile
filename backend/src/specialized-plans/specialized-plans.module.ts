import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SpecializedPlansService } from './specialized-plans.service';
import { SpecializedPlansController } from './specialized-plans.controller';
import {
  SpecializedPlan,
  SpecializedPlanSchema,
} from './schemas/specialized-plan.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SpecializedPlan.name, schema: SpecializedPlanSchema },
      { name: Child.name, schema: ChildSchema },
    ]),
  ],
  providers: [SpecializedPlansService],
  controllers: [SpecializedPlansController],
  exports: [SpecializedPlansService],
})
export class SpecializedPlansModule {}
