import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { EngagementController } from "./engagement.controller";
import { EngagementService } from "./engagement.service";
import { ChildSchema } from "@/modules/children/infrastructure/persistence/mongo/child.schema";
import {
  GameSessionMongoSchema,
  BadgeMongoSchema,
  ChildBadgeMongoSchema,
} from "@/modules/gamification/infrastructure/persistence/mongo/gamification.schema";
import { TaskReminderMongoSchema } from "@/modules/nutrition/infrastructure/persistence/mongo/nutrition.schema";
import { UserSchema } from "@/modules/users/infrastructure/persistence/mongo/user.schema";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: "Child", schema: ChildSchema },
      { name: "GameSession", schema: GameSessionMongoSchema },
      { name: "TaskReminder", schema: TaskReminderMongoSchema },
      { name: "ChildBadge", schema: ChildBadgeMongoSchema },
      { name: "Badge", schema: BadgeMongoSchema },
      { name: "User", schema: UserSchema },
    ]),
  ],
  controllers: [EngagementController],
  providers: [EngagementService],
  exports: [EngagementService],
})
export class EngagementModule {}
