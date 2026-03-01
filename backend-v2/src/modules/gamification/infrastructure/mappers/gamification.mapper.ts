import { Types } from 'mongoose';
import {
  BadgeEntity, ChildBadgeEntity, PointsEntity, GameSessionEntity,
  BadgeType, GameType,
} from '../../domain/entities/gamification.entity';

export class BadgeMapper {
  static toDomain(raw: Record<string, any>): BadgeEntity {
    const req = raw.requirements instanceof Map
      ? Object.fromEntries(raw.requirements)
      : (raw.requirements ?? {});
    return BadgeEntity.reconstitute(raw._id.toString(), {
      badgeId: raw.badgeId, name: raw.name, description: raw.description,
      type: raw.type as BadgeType, iconUrl: raw.iconUrl,
      requirements: req, isActive: raw.isActive ?? true,
    });
  }
  static toPersistence(e: BadgeEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id), badgeId: e.badgeId, name: e.name,
      description: e.description, type: e.type, iconUrl: e.iconUrl,
      requirements: new Map(Object.entries(e.requirements)), isActive: e.isActive,
    };
  }
}

export class ChildBadgeMapper {
  static toDomain(raw: Record<string, any>): ChildBadgeEntity {
    return ChildBadgeEntity.reconstitute(raw._id.toString(), {
      childId: raw.childId?.toString() ?? '',
      badgeId: raw.badgeId?.toString() ?? '',
      badgeIdString: raw.badgeIdString ?? '',
      earnedAt: raw.earnedAt ?? new Date(),
      gameType: raw.gameType,
    });
  }
  static toPersistence(e: ChildBadgeEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id),
      childId: new Types.ObjectId(e.childId),
      badgeId: new Types.ObjectId(e.badgeId),
      badgeIdString: e.badgeIdString,
      earnedAt: e.earnedAt,
      gameType: e.gameType,
    };
  }
}

export class PointsMapper {
  static toDomain(raw: Record<string, any>): PointsEntity {
    const byGame = raw.pointsByGame instanceof Map
      ? Object.fromEntries(raw.pointsByGame)
      : (raw.pointsByGame ?? {});
    return PointsEntity.reconstitute(raw._id.toString(), {
      childId: raw.childId?.toString() ?? '',
      totalPoints: raw.totalPoints ?? 0,
      pointsByGame: byGame,
      gamesPlayed: raw.gamesPlayed ?? [],
      gamesCompleted: raw.gamesCompleted ?? 0,
      currentStreak: raw.currentStreak ?? 0,
      lastPlayedDate: raw.lastPlayedDate,
    });
  }
  static toPersistence(e: PointsEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id),
      childId: new Types.ObjectId(e.childId),
      totalPoints: e.totalPoints,
      pointsByGame: new Map(Object.entries(e.pointsByGame)),
      gamesPlayed: e.gamesPlayed,
      gamesCompleted: e.gamesCompleted,
      currentStreak: e.currentStreak,
      lastPlayedDate: e.lastPlayedDate,
    };
  }
}

export class GameSessionMapper {
  static toDomain(raw: Record<string, any>): GameSessionEntity {
    const metrics = raw.metrics instanceof Map
      ? Object.fromEntries(raw.metrics)
      : (raw.metrics ?? {});
    return GameSessionEntity.reconstitute(raw._id.toString(), {
      childId: raw.childId?.toString() ?? '',
      gameType: raw.gameType as GameType,
      level: raw.level,
      completed: raw.completed ?? false,
      score: raw.score ?? 0,
      timeSpentSeconds: raw.timeSpentSeconds ?? 0,
      metrics,
      createdAt: raw.createdAt,
    });
  }
  static toPersistence(e: GameSessionEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(e.id),
      childId: new Types.ObjectId(e.childId),
      gameType: e.gameType,
      level: e.level,
      completed: e.completed,
      score: e.score,
      timeSpentSeconds: e.timeSpentSeconds,
      metrics: new Map(Object.entries(e.metrics)),
    };
  }
}
