import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NutritionController } from './nutrition.controller';
import { RemindersController } from './reminders.controller';
import { NutritionService } from './nutrition.service';
import { RemindersService } from './reminders.service';
import {
  NutritionPlan,
  NutritionPlanSchema,
} from './schemas/nutrition-plan.schema';
import {
  TaskReminder,
  TaskReminderSchema,
} from './schemas/task-reminder.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import { User, UserSchema } from '../users/schemas/user.schema';

import { HealthModule } from '../health/health.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NutritionPlan.name, schema: NutritionPlanSchema },
      { name: TaskReminder.name, schema: TaskReminderSchema },
      { name: Child.name, schema: ChildSchema },
      { name: User.name, schema: UserSchema },
    ]),
    HealthModule,
  ],
  controllers: [NutritionController, RemindersController],
  providers: [NutritionService, RemindersService],
  exports: [NutritionService, RemindersService],
})
export class NutritionModule {}
