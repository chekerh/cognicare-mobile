import {
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Points, PointsDocument } from './schemas/points.schema';
import { Badge, BadgeDocument, BadgeType } from './schemas/badge.schema';
import { ChildBadge, ChildBadgeDocument } from './schemas/child-badge.schema';
import {
  GameSession,
  GameSessionDocument,
  GameType,
} from './schemas/game-session.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import { RecordGameSessionDto } from './dto/record-game-session.dto';

export interface BadgeEarned {
  badgeId: string;
  name: string;
  description?: string;
  iconUrl?: string;
  earnedAt: Date;
}

@Injectable()
export class GamificationService {
  private readonly logger = new Logger(GamificationService.name);

  constructor(
    @InjectModel(Points.name) private pointsModel: Model<PointsDocument>,
    @InjectModel(Badge.name) private badgeModel: Model<BadgeDocument>,
    @InjectModel(ChildBadge.name)
    private childBadgeModel: Model<ChildBadgeDocument>,
    @InjectModel(GameSession.name)
    private gameSessionModel: Model<GameSessionDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
  ) {}

  /**
   * Record a game session and update points/badges.
   * Returns points earned, total points, and any badges unlocked.
   */
  async recordGameSession(
    childId: string,
    dto: RecordGameSessionDto,
  ): Promise<{
    pointsEarned: number;
    totalPoints: number;
    badgesEarned: BadgeEarned[];
    currentStreak: number;
  }> {
    const child = await this.childModel.findById(childId).exec();
    if (!child) throw new NotFoundException('Child not found');

    const cid = new Types.ObjectId(childId);
    const pointsEarned = this.calculatePoints(dto);
    const now = new Date();

    // Get or create points document
    let points = await this.pointsModel.findOne({ childId: cid }).exec();
    if (!points) {
      points = await this.pointsModel.create({
        childId: cid,
        totalPoints: 0,
        pointsByGame: new Map(),
        gamesPlayed: [],
        gamesCompleted: 0,
        currentStreak: 0,
      });
    }

    // Update points
    const gameTypeKey = dto.gameType;
    const currentGamePoints = points.pointsByGame.get(gameTypeKey) || 0;
    points.pointsByGame.set(gameTypeKey, currentGamePoints + pointsEarned);
    points.totalPoints += pointsEarned;

    // Update games played/completed
    if (!points.gamesPlayed.includes(gameTypeKey)) {
      points.gamesPlayed.push(gameTypeKey);
    }
    if (dto.completed) {
      points.gamesCompleted += 1;
    }

    // Update streak
    const lastPlayed = points.lastPlayedDate
      ? new Date(points.lastPlayedDate)
      : null;
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const lastPlayedDate = lastPlayed
      ? new Date(lastPlayed.getFullYear(), lastPlayed.getMonth(), lastPlayed.getDate())
      : null;

    if (!lastPlayedDate || lastPlayedDate.getTime() < today.getTime() - 86400000) {
      // Reset streak if more than 1 day gap
      points.currentStreak = 1;
    } else if (lastPlayedDate.getTime() === today.getTime() - 86400000) {
      // Continue streak if played yesterday
      points.currentStreak += 1;
    } else if (lastPlayedDate.getTime() < today.getTime()) {
      // Same day, keep streak
      // streak stays the same
    }

    points.lastPlayedDate = now;
    await points.save();

    // Save game session
    await this.gameSessionModel.create({
      childId: cid,
      gameType: dto.gameType,
      level: dto.level,
      completed: dto.completed,
      score: pointsEarned,
      timeSpentSeconds: dto.timeSpentSeconds || 0,
      metrics: dto.metrics ? new Map(Object.entries(dto.metrics)) : new Map(),
    });

    // Check and award badges
    const badgesEarned = await this.checkAndAwardBadges(cid, points);

    return {
      pointsEarned,
      totalPoints: points.totalPoints,
      badgesEarned,
      currentStreak: points.currentStreak,
    };
  }

  /**
   * Calculate points for a game session based on completion and performance.
   */
  private calculatePoints(dto: RecordGameSessionDto): number {
    if (!dto.completed) return 0;

    const basePoints: Record<GameType, number> = {
      [GameType.MATCHING]: 50,
      [GameType.SHAPE_SORTING]: 50,
      [GameType.STAR_TRACER]: 75,
      [GameType.BASKET_SORT]: 50,
    };

    let points = basePoints[dto.gameType] || 50;

    // Bonus for speed (if timeSpentSeconds provided)
    if (dto.timeSpentSeconds && dto.timeSpentSeconds > 0) {
      const speedBonus = Math.max(0, 30 - dto.timeSpentSeconds / 10);
      points += Math.floor(speedBonus);
    }

    // Bonus for level (if applicable)
    if (dto.level && dto.level > 1) {
      points += dto.level * 5;
    }

    return Math.max(0, points);
  }

  /**
   * Check if child qualifies for any badges and award them.
   */
  private async checkAndAwardBadges(
    childId: Types.ObjectId,
    points: PointsDocument,
  ): Promise<BadgeEarned[]> {
    const badges = await this.badgeModel.find({ isActive: true }).lean().exec();
    const earnedBadges: BadgeEarned[] = [];

    for (const badge of badges) {
      // Check if already earned
      const alreadyEarned = await this.childBadgeModel
        .findOne({
          childId,
          badgeIdString: badge.badgeId,
        })
        .exec();
      if (alreadyEarned) continue;

      // Check requirements (badge from lean() may be plain object, not Map)
      let qualifies = true;
      const requirements = badge.requirements ?? {};
      const requirementEntries = requirements instanceof Map
        ? Array.from(requirements.entries())
        : Object.entries(requirements);
      for (const [key, requiredValue] of requirementEntries) {
        let actualValue = 0;
        switch (key) {
          case 'gamesCompleted':
            actualValue = points.gamesCompleted;
            break;
          case 'totalPoints':
            actualValue = points.totalPoints;
            break;
          case 'currentStreak':
            actualValue = points.currentStreak;
            break;
          case 'gamesPlayed':
            actualValue = points.gamesPlayed.length;
            break;
          default:
            // Check pointsByGame
            const gamePoints = points.pointsByGame.get(key);
            if (gamePoints !== undefined) {
              actualValue = gamePoints;
            }
        }

        if (actualValue < requiredValue) {
          qualifies = false;
          break;
        }
      }

      if (qualifies) {
        // Award badge
        await this.childBadgeModel.create({
          childId,
          badgeId: badge._id,
          badgeIdString: badge.badgeId,
          earnedAt: new Date(),
        });

        earnedBadges.push({
          badgeId: badge.badgeId,
          name: badge.name,
          description: badge.description,
          iconUrl: badge.iconUrl,
          earnedAt: new Date(),
        });

        this.logger.log(
          `Badge awarded: ${badge.badgeId} to child ${childId}`,
        );
      }
    }

    return earnedBadges;
  }

  /**
   * Get child's gamification stats (points, badges, progress).
   */
  async getChildStats(childId: string) {
    const cid = new Types.ObjectId(childId);
    const child = await this.childModel.findById(childId).exec();
    if (!child) throw new NotFoundException('Child not found');

    const points = await this.pointsModel.findOne({ childId: cid }).lean().exec();
    const badges = await this.childBadgeModel
      .find({ childId: cid })
      .populate('badgeId')
      .sort({ earnedAt: -1 })
      .lean()
      .exec();

    const recentSessions = await this.gameSessionModel
      .find({ childId: cid })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean()
      .exec();

    const rawPointsByGame = points?.pointsByGame;
    const pointsByGameMap =
      rawPointsByGame == null
        ? {}
        : rawPointsByGame instanceof Map
          ? Object.fromEntries(Array.from(rawPointsByGame.entries()))
          : (rawPointsByGame as Record<string, number>);

    return {
      totalPoints: points?.totalPoints || 0,
      pointsByGame: pointsByGameMap,
      gamesCompleted: points?.gamesCompleted || 0,
      gamesPlayed: points?.gamesPlayed || [],
      currentStreak: points?.currentStreak || 0,
      badges: badges.map((b) => ({
        badgeId: b.badgeIdString,
        name: (b.badgeId as any)?.name,
        description: (b.badgeId as any)?.description,
        iconUrl: (b.badgeId as any)?.iconUrl,
        earnedAt: b.earnedAt,
      })),
      recentSessions: recentSessions.map((s) => ({
        gameType: s.gameType,
        level: s.level,
        completed: s.completed,
        score: s.score,
        timeSpentSeconds: s.timeSpentSeconds,
        createdAt: s.createdAt,
      })),
    };
  }

  /**
   * Initialize default badges (call this on module init or via migration).
   */
  async initializeDefaultBadges() {
    const defaultBadges = [
      {
        badgeId: 'first_game',
        name: 'Premier Jeu',
        description: 'Complété votre premier jeu !',
        type: BadgeType.GAMES_COMPLETED,
        requirements: { gamesCompleted: 1 },
      },
      {
        badgeId: 'points_100',
        name: '100 Points',
        description: 'Atteint 100 points !',
        type: BadgeType.POINTS_MILESTONE,
        requirements: { totalPoints: 100 },
      },
      {
        badgeId: 'points_500',
        name: '500 Points',
        description: 'Atteint 500 points !',
        type: BadgeType.POINTS_MILESTONE,
        requirements: { totalPoints: 500 },
      },
      {
        badgeId: 'streak_7',
        name: 'Série de 7 Jours',
        description: 'Joué 7 jours consécutifs !',
        type: BadgeType.STREAK,
        requirements: { currentStreak: 7 },
      },
      {
        badgeId: 'matching_master',
        name: 'Maître de la Mémoire',
        description: '100 points dans Match Pairs',
        type: BadgeType.GAME_SPECIFIC,
        requirements: { matching: 100 },
      },
      {
        badgeId: 'star_tracer_pro',
        name: 'Pro du Tracé',
        description: '200 points dans Star Tracer',
        type: BadgeType.GAME_SPECIFIC,
        requirements: { star_tracer: 200 },
      },
    ];

    for (const badgeData of defaultBadges) {
      const existing = await this.badgeModel
        .findOne({ badgeId: badgeData.badgeId })
        .exec();
      if (!existing) {
        await this.badgeModel.create({
          ...badgeData,
          requirements: new Map(Object.entries(badgeData.requirements)),
        });
        this.logger.log(`Created default badge: ${badgeData.badgeId}`);
      }
    }
  }
}
