import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { ProgressAiController } from "./progress-ai.controller";
import { ProgressAiService } from "./progress-ai.service";
import { ProgressContextService } from "./progress-context.service";
import { LlmService } from "./llm.service";
import {
  RecommendationFeedback,
  RecommendationFeedbackSchema,
} from "./schemas/recommendation-feedback.schema";
import {
  ParentFeedbackRequest,
  ParentFeedbackRequestSchema,
} from "./schemas/parent-feedback-request.schema";
import {
  ParentFeedback,
  ParentFeedbackSchema,
} from "./schemas/parent-feedback.schema";
import {
  ChildMongoSchema,
  ChildSchema,
} from "@/modules/children/infrastructure/persistence/mongo/child.schema";
import {
  UserMongoSchema,
  UserSchema,
} from "@/modules/users/infrastructure/persistence/mongo/user.schema";
import {
  OrganizationMongoSchema,
  OrganizationSchema,
} from "@/modules/organization/infrastructure/persistence/mongo/organization.schema";
import { TaskReminderMongoSchema } from "@/modules/nutrition/infrastructure/persistence/mongo/nutrition.schema";
import {
  SpecializedPlan,
  SpecializedPlanSchema,
} from "@/modules/specialized-plans/schemas/specialized-plan.schema";
import { SpecializedPlansModule } from "@/modules/specialized-plans/specialized-plans.module";
import { NutritionModule } from "@/modules/nutrition/nutrition.module";

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: RecommendationFeedback.name,
        schema: RecommendationFeedbackSchema,
      },
      { name: ParentFeedbackRequest.name, schema: ParentFeedbackRequestSchema },
      { name: ParentFeedback.name, schema: ParentFeedbackSchema },
      { name: ChildMongoSchema.name, schema: ChildSchema },
      { name: UserMongoSchema.name, schema: UserSchema },
      { name: OrganizationMongoSchema.name, schema: OrganizationSchema },
      { name: "TaskReminder", schema: TaskReminderMongoSchema },
      { name: SpecializedPlan.name, schema: SpecializedPlanSchema },
    ]),
    SpecializedPlansModule,
    NutritionModule,
  ],
  controllers: [ProgressAiController],
  providers: [ProgressAiService, ProgressContextService, LlmService],
  exports: [ProgressAiService],
})
export class ProgressAiModule {}
