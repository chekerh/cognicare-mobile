import { BadgeEntity, ChildBadgeEntity, PointsEntity, GameSessionEntity } from '../entities/gamification.entity';

export interface IBadgeRepository {
  findAll(activeOnly?: boolean): Promise<BadgeEntity[]>;
  findByBadgeId(badgeId: string): Promise<BadgeEntity | null>;
  save(entity: BadgeEntity): Promise<BadgeEntity>;
}

export interface IChildBadgeRepository {
  findByChildId(childId: string): Promise<ChildBadgeEntity[]>;
  findOne(childId: string, badgeIdString: string): Promise<ChildBadgeEntity | null>;
  save(entity: ChildBadgeEntity): Promise<ChildBadgeEntity>;
}

export interface IPointsRepository {
  findByChildId(childId: string): Promise<PointsEntity | null>;
  save(entity: PointsEntity): Promise<PointsEntity>;
  update(entity: PointsEntity): Promise<PointsEntity>;
}

export interface IGameSessionRepository {
  findByChildId(childId: string, limit?: number): Promise<GameSessionEntity[]>;
  save(entity: GameSessionEntity): Promise<GameSessionEntity>;
}
