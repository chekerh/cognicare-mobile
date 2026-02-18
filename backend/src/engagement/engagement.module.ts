import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EngagementController } from './engagement.controller';
import { EngagementService } from './engagement.service';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import {
  GameSession,
  GameSessionSchema,
} from '../gamification/schemas/game-session.schema';
import {
  TaskReminder,
  TaskReminderSchema,
} from '../nutrition/schemas/task-reminder.schema';
import {
  ChildBadge,
  ChildBadgeSchema,
} from '../gamification/schemas/child-badge.schema';
import { Badge, BadgeSchema } from '../gamification/schemas/badge.schema';
import { User, UserSchema } from '../users/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Child.name, schema: ChildSchema },
      { name: GameSession.name, schema: GameSessionSchema },
      { name: TaskReminder.name, schema: TaskReminderSchema },
      { name: ChildBadge.name, schema: ChildBadgeSchema },
      { name: Badge.name, schema: BadgeSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [EngagementController],
  providers: [EngagementService],
  exports: [EngagementService],
})
export class EngagementModule {}
