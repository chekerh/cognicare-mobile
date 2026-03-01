import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  BadgeMongoSchema,
  ChildBadgeMongoSchema,
  PointsMongoSchema,
  GameSessionMongoSchema,
} from "./infrastructure/persistence/mongo/gamification.schema";
import {
  BadgeMongoRepository,
  ChildBadgeMongoRepository,
  PointsMongoRepository,
  GameSessionMongoRepository,
} from "./infrastructure/persistence/mongo/gamification.mongo-repository";
import {
  BADGE_REPOSITORY_TOKEN,
  CHILD_BADGE_REPOSITORY_TOKEN,
  POINTS_REPOSITORY_TOKEN,
  GAME_SESSION_REPOSITORY_TOKEN,
  RecordGameSessionUseCase,
  GetChildStatsUseCase,
  InitializeDefaultBadgesUseCase,
} from "./application/use-cases/gamification.use-cases";
import { GamificationController } from "./interface/http/gamification.controller";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: "Badge", schema: BadgeMongoSchema },
      { name: "ChildBadge", schema: ChildBadgeMongoSchema },
      { name: "Points", schema: PointsMongoSchema },
      { name: "GameSession", schema: GameSessionMongoSchema },
    ]),
  ],
  controllers: [GamificationController],
  providers: [
    { provide: BADGE_REPOSITORY_TOKEN, useClass: BadgeMongoRepository },
    {
      provide: CHILD_BADGE_REPOSITORY_TOKEN,
      useClass: ChildBadgeMongoRepository,
    },
    { provide: POINTS_REPOSITORY_TOKEN, useClass: PointsMongoRepository },
    {
      provide: GAME_SESSION_REPOSITORY_TOKEN,
      useClass: GameSessionMongoRepository,
    },
    RecordGameSessionUseCase,
    GetChildStatsUseCase,
    InitializeDefaultBadgesUseCase,
  ],
  exports: [GAME_SESSION_REPOSITORY_TOKEN, POINTS_REPOSITORY_TOKEN],
})
export class GamificationModule {}
