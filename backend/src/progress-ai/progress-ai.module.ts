import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProgressAiController } from './progress-ai.controller';
import { ProgressAiService } from './progress-ai.service';
import { ProgressContextService } from './progress-context.service';
import { LlmService } from './llm.service';
import {
  RecommendationFeedback,
  RecommendationFeedbackSchema,
} from './schemas/recommendation-feedback.schema';
import {
  ParentFeedbackRequest,
  ParentFeedbackRequestSchema,
} from './schemas/parent-feedback-request.schema';
import {
  ParentFeedback,
  ParentFeedbackSchema,
} from './schemas/parent-feedback.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import {
  Organization,
  OrganizationSchema,
} from '../organization/schemas/organization.schema';
import {
  TaskReminder,
  TaskReminderSchema,
} from '../nutrition/schemas/task-reminder.schema';
import {
  SpecializedPlan,
  SpecializedPlanSchema,
} from '../specialized-plans/schemas/specialized-plan.schema';
import { SpecializedPlansModule } from '../specialized-plans/specialized-plans.module';
import { NutritionModule } from '../nutrition/nutrition.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: RecommendationFeedback.name,
        schema: RecommendationFeedbackSchema,
      },
      { name: ParentFeedbackRequest.name, schema: ParentFeedbackRequestSchema },
      { name: ParentFeedback.name, schema: ParentFeedbackSchema },
      { name: Child.name, schema: ChildSchema },
      { name: User.name, schema: UserSchema },
      { name: Organization.name, schema: OrganizationSchema },
      { name: TaskReminder.name, schema: TaskReminderSchema },
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
