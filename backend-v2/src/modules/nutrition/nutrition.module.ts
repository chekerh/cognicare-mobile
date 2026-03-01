import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";

import {
  NutritionPlanMongoSchema,
  TaskReminderMongoSchema,
} from "./infrastructure/persistence/mongo/nutrition.schema";
import {
  NutritionPlanMongoRepository,
  TaskReminderMongoRepository,
} from "./infrastructure/persistence/mongo/nutrition.mongo-repository";
import {
  NUTRITION_PLAN_REPOSITORY_TOKEN,
  TASK_REMINDER_REPOSITORY_TOKEN,
  CreateNutritionPlanUseCase,
  GetNutritionPlanByChildUseCase,
  UpdateNutritionPlanUseCase,
  DeleteNutritionPlanUseCase,
  CreateTaskReminderUseCase,
  GetRemindersByChildUseCase,
  GetTodayRemindersUseCase,
  UpdateTaskReminderUseCase,
  CompleteTaskUseCase,
  DeleteTaskReminderUseCase,
  GetCompletionStatsUseCase,
} from "./application/use-cases/nutrition.use-cases";
import { NutritionController } from "./interface/http/nutrition.controller";
import { RemindersController } from "./interface/http/reminders.controller";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: "NutritionPlan", schema: NutritionPlanMongoSchema },
      { name: "TaskReminder", schema: TaskReminderMongoSchema },
    ]),
  ],
  controllers: [NutritionController, RemindersController],
  providers: [
    {
      provide: NUTRITION_PLAN_REPOSITORY_TOKEN,
      useClass: NutritionPlanMongoRepository,
    },
    {
      provide: TASK_REMINDER_REPOSITORY_TOKEN,
      useClass: TaskReminderMongoRepository,
    },
    CreateNutritionPlanUseCase,
    GetNutritionPlanByChildUseCase,
    UpdateNutritionPlanUseCase,
    DeleteNutritionPlanUseCase,
    CreateTaskReminderUseCase,
    GetRemindersByChildUseCase,
    GetTodayRemindersUseCase,
    UpdateTaskReminderUseCase,
    CompleteTaskUseCase,
    DeleteTaskReminderUseCase,
    GetCompletionStatsUseCase,
  ],
  exports: [TASK_REMINDER_REPOSITORY_TOKEN, GetCompletionStatsUseCase],
})
export class NutritionModule {}
