import { Inject, Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { Result, ok } from "../../../../core/result";
import {
  IBadgeRepository,
  IChildBadgeRepository,
  IPointsRepository,
  IGameSessionRepository,
} from "../../domain/repositories/gamification.repository.interface";
import {
  BadgeEntity,
  BadgeType,
  ChildBadgeEntity,
  GameSessionEntity,
  GameType,
  PointsEntity,
} from "../../domain/entities/gamification.entity";

export const BADGE_REPOSITORY_TOKEN = Symbol("IBadgeRepository");
export const CHILD_BADGE_REPOSITORY_TOKEN = Symbol("IChildBadgeRepository");
export const POINTS_REPOSITORY_TOKEN = Symbol("IPointsRepository");
export const GAME_SESSION_REPOSITORY_TOKEN = Symbol("IGameSessionRepository");

/* ─── helpers ─── */
function calculatePoints(
  gameType: GameType,
  completed: boolean,
  timeSpent?: number,
  level?: number,
): number {
  if (!completed || gameType === GameType.CHILD_MODE) return 0;
  const base: Record<string, number> = {
    matching: 50,
    shape_sorting: 50,
    star_tracer: 75,
    basket_sort: 50,
    child_mode: 0,
  };
  let pts = base[gameType] ?? 50;
  if (timeSpent && timeSpent > 0)
    pts += Math.max(0, Math.floor(30 - timeSpent / 10));
  if (level && level > 1) pts += level * 5;
  return Math.max(0, pts);
}

/* ─── RecordGameSession ─── */
@Injectable()
export class RecordGameSessionUseCase {
  constructor(
    @Inject(POINTS_REPOSITORY_TOKEN)
    private readonly pointsRepo: IPointsRepository,
    @Inject(GAME_SESSION_REPOSITORY_TOKEN)
    private readonly sessionRepo: IGameSessionRepository,
    @Inject(BADGE_REPOSITORY_TOKEN)
    private readonly badgeRepo: IBadgeRepository,
    @Inject(CHILD_BADGE_REPOSITORY_TOKEN)
    private readonly childBadgeRepo: IChildBadgeRepository,
  ) {}

  async execute(
    childId: string,
    dto: {
      gameType: GameType;
      level?: number;
      completed: boolean;
      score?: number;
      timeSpentSeconds?: number;
      metrics?: Record<string, number>;
    },
  ): Promise<
    Result<
      {
        pointsEarned: number;
        totalPoints: number;
        badgesEarned: any[];
        currentStreak: number;
      },
      string
    >
  > {
    const pointsEarned = calculatePoints(
      dto.gameType,
      dto.completed,
      dto.timeSpentSeconds,
      dto.level,
    );

    let points = await this.pointsRepo.findByChildId(childId);
    if (!points) {
      points = PointsEntity.create(childId);
      points = await this.pointsRepo.save(points);
    }

    points.addPoints(dto.gameType, pointsEarned, dto.completed);
    points.updateStreak();
    await this.pointsRepo.update(points);

    await this.sessionRepo.save(
      GameSessionEntity.create({
        childId,
        gameType: dto.gameType,
        level: dto.level,
        completed: dto.completed,
        score: pointsEarned,
        timeSpentSeconds: dto.timeSpentSeconds ?? 0,
        metrics: dto.metrics ?? {},
      }),
    );

    const badgesEarned = await this.checkAndAwardBadges(childId, points);

    return ok({
      pointsEarned,
      totalPoints: points.totalPoints,
      badgesEarned,
      currentStreak: points.currentStreak,
    });
  }

  private async checkAndAwardBadges(childId: string, points: PointsEntity) {
    const badges = await this.badgeRepo.findAll(true);
    const earned: any[] = [];
    for (const badge of badges) {
      const existing = await this.childBadgeRepo.findOne(
        childId,
        badge.badgeId,
      );
      if (existing) continue;
      let qualifies = true;
      for (const [key, val] of Object.entries(badge.requirements)) {
        let actual = 0;
        switch (key) {
          case "gamesCompleted":
            actual = points.gamesCompleted;
            break;
          case "totalPoints":
            actual = points.totalPoints;
            break;
          case "currentStreak":
            actual = points.currentStreak;
            break;
          case "gamesPlayed":
            actual = points.gamesPlayed.length;
            break;
          default:
            actual = points.pointsByGame[key] ?? 0;
        }
        if (actual < val) {
          qualifies = false;
          break;
        }
      }
      if (qualifies) {
        await this.childBadgeRepo.save(
          ChildBadgeEntity.create({
            childId,
            badgeId: badge.id,
            badgeIdString: badge.badgeId,
            earnedAt: new Date(),
          }),
        );
        earned.push({
          badgeId: badge.badgeId,
          name: badge.name,
          description: badge.description,
          iconUrl: badge.iconUrl,
          earnedAt: new Date(),
        });
      }
    }
    return earned;
  }
}

/* ─── GetChildStats ─── */
@Injectable()
export class GetChildStatsUseCase {
  constructor(
    @Inject(POINTS_REPOSITORY_TOKEN)
    private readonly pointsRepo: IPointsRepository,
    @Inject(GAME_SESSION_REPOSITORY_TOKEN)
    private readonly sessionRepo: IGameSessionRepository,
    @Inject(CHILD_BADGE_REPOSITORY_TOKEN)
    private readonly childBadgeRepo: IChildBadgeRepository,
  ) {}

  async execute(childId: string): Promise<Result<Record<string, any>, string>> {
    const points = await this.pointsRepo.findByChildId(childId);
    const badges = await this.childBadgeRepo.findByChildId(childId);
    const sessions = await this.sessionRepo.findByChildId(childId, 10);
    return ok({
      totalPoints: points?.totalPoints ?? 0,
      pointsByGame: points?.pointsByGame ?? {},
      gamesCompleted: points?.gamesCompleted ?? 0,
      gamesPlayed: points?.gamesPlayed ?? [],
      currentStreak: points?.currentStreak ?? 0,
      badges: badges.map((b) => ({
        badgeId: b.badgeIdString,
        earnedAt: b.earnedAt,
      })),
      recentSessions: sessions.map((s) => ({
        gameType: s.gameType,
        level: s.level,
        completed: s.completed,
        score: s.score,
        timeSpentSeconds: s.timeSpentSeconds,
        createdAt: s.createdAt,
      })),
    });
  }
}

/* ─── InitializeDefaultBadges ─── */
@Injectable()
export class InitializeDefaultBadgesUseCase implements OnModuleInit {
  private readonly logger = new Logger(InitializeDefaultBadgesUseCase.name);
  constructor(
    @Inject(BADGE_REPOSITORY_TOKEN)
    private readonly badgeRepo: IBadgeRepository,
  ) {}

  async onModuleInit() {
    await this.execute();
  }

  async execute(): Promise<void> {
    const defaults: Array<{
      badgeId: string;
      name: string;
      description: string;
      type: BadgeType;
      requirements: Record<string, number>;
    }> = [
      {
        badgeId: "first_game",
        name: "Premier Jeu",
        description: "Complété votre premier jeu !",
        type: BadgeType.GAMES_COMPLETED,
        requirements: { gamesCompleted: 1 },
      },
      {
        badgeId: "points_100",
        name: "100 Points",
        description: "Atteint 100 points !",
        type: BadgeType.POINTS_MILESTONE,
        requirements: { totalPoints: 100 },
      },
      {
        badgeId: "points_500",
        name: "500 Points",
        description: "Atteint 500 points !",
        type: BadgeType.POINTS_MILESTONE,
        requirements: { totalPoints: 500 },
      },
      {
        badgeId: "streak_7",
        name: "Série de 7 Jours",
        description: "Joué 7 jours consécutifs !",
        type: BadgeType.STREAK,
        requirements: { currentStreak: 7 },
      },
      {
        badgeId: "matching_master",
        name: "Maître de la Mémoire",
        description: "100 points dans Match Pairs",
        type: BadgeType.GAME_SPECIFIC,
        requirements: { matching: 100 },
      },
      {
        badgeId: "star_tracer_pro",
        name: "Pro du Tracé",
        description: "200 points dans Star Tracer",
        type: BadgeType.GAME_SPECIFIC,
        requirements: { star_tracer: 200 },
      },
    ];
    for (const d of defaults) {
      const existing = await this.badgeRepo.findByBadgeId(d.badgeId);
      if (!existing) {
        await this.badgeRepo.save(BadgeEntity.create({ ...d, isActive: true }));
        this.logger.log(`Created badge: ${d.badgeId}`);
      }
    }
  }
}
