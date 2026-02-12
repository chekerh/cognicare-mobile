import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { GamificationController } from './gamification.controller';
import { GamificationService } from './gamification.service';
import { Points, PointsSchema } from './schemas/points.schema';
import { Badge, BadgeSchema } from './schemas/badge.schema';
import { ChildBadge, ChildBadgeSchema } from './schemas/child-badge.schema';
import { GameSession, GameSessionSchema } from './schemas/game-session.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Points.name, schema: PointsSchema },
      { name: Badge.name, schema: BadgeSchema },
      { name: ChildBadge.name, schema: ChildBadgeSchema },
      { name: GameSession.name, schema: GameSessionSchema },
      { name: Child.name, schema: ChildSchema },
    ]),
  ],
  controllers: [GamificationController],
  providers: [GamificationService],
  exports: [GamificationService],
})
export class GamificationModule {
  constructor(private gamificationService: GamificationService) {}

  async onModuleInit() {
    // Initialize default badges on module startup
    await this.gamificationService.initializeDefaultBadges();
  }
}
