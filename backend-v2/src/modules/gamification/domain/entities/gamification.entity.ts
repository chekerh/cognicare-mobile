import { Entity } from '../../../../core/entity.base';

/* ─── Enums ─── */
export enum BadgeType {
  GAMES_COMPLETED = 'games_completed',
  POINTS_MILESTONE = 'points_milestone',
  STREAK = 'streak',
  GAME_SPECIFIC = 'game_specific',
  WEEKLY_CHALLENGE = 'weekly_challenge',
}

export enum GameType {
  MATCHING = 'matching',
  SHAPE_SORTING = 'shape_sorting',
  STAR_TRACER = 'star_tracer',
  BASKET_SORT = 'basket_sort',
  CHILD_MODE = 'child_mode',
}

/* ─── BadgeEntity ─── */
export interface BadgeProps {
  badgeId: string;
  name: string;
  description?: string;
  type: BadgeType;
  iconUrl?: string;
  requirements: Record<string, number>;
  isActive: boolean;
}

export class BadgeEntity extends Entity<BadgeProps> {
  static create(props: BadgeProps): BadgeEntity { return new BadgeEntity(props, Entity.generateId()); }
  static reconstitute(id: string, props: BadgeProps): BadgeEntity { return new BadgeEntity(props, id); }
  get badgeId() { return this.props.badgeId; }
  get name() { return this.props.name; }
  get description() { return this.props.description; }
  get type() { return this.props.type; }
  get iconUrl() { return this.props.iconUrl; }
  get requirements() { return this.props.requirements; }
  get isActive() { return this.props.isActive; }
}

/* ─── ChildBadgeEntity ─── */
export interface ChildBadgeProps {
  childId: string;
  badgeId: string;
  badgeIdString: string;
  earnedAt: Date;
  gameType?: string;
}

export class ChildBadgeEntity extends Entity<ChildBadgeProps> {
  static create(props: ChildBadgeProps): ChildBadgeEntity { return new ChildBadgeEntity(props, Entity.generateId()); }
  static reconstitute(id: string, props: ChildBadgeProps): ChildBadgeEntity { return new ChildBadgeEntity(props, id); }
  get childId() { return this.props.childId; }
  get badgeId() { return this.props.badgeId; }
  get badgeIdString() { return this.props.badgeIdString; }
  get earnedAt() { return this.props.earnedAt; }
  get gameType() { return this.props.gameType; }
}

/* ─── PointsEntity ─── */
export interface PointsProps {
  childId: string;
  totalPoints: number;
  pointsByGame: Record<string, number>;
  gamesPlayed: string[];
  gamesCompleted: number;
  currentStreak: number;
  lastPlayedDate?: Date;
}

export class PointsEntity extends Entity<PointsProps> {
  static create(childId: string): PointsEntity {
    return new PointsEntity({ childId, totalPoints: 0, pointsByGame: {}, gamesPlayed: [], gamesCompleted: 0, currentStreak: 0 }, Entity.generateId());
  }
  static reconstitute(id: string, props: PointsProps): PointsEntity { return new PointsEntity(props, id); }
  get childId() { return this.props.childId; }
  get totalPoints() { return this.props.totalPoints; }
  get pointsByGame() { return this.props.pointsByGame; }
  get gamesPlayed() { return this.props.gamesPlayed; }
  get gamesCompleted() { return this.props.gamesCompleted; }
  get currentStreak() { return this.props.currentStreak; }
  get lastPlayedDate() { return this.props.lastPlayedDate; }

  addPoints(gameType: string, points: number, completed: boolean): void {
    this.props.pointsByGame[gameType] = (this.props.pointsByGame[gameType] ?? 0) + points;
    this.props.totalPoints += points;
    if (!this.props.gamesPlayed.includes(gameType)) this.props.gamesPlayed.push(gameType);
    if (completed) this.props.gamesCompleted += 1;
  }

  updateStreak(): void {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const last = this.props.lastPlayedDate ? new Date(this.props.lastPlayedDate) : null;
    const lastDay = last ? new Date(last.getFullYear(), last.getMonth(), last.getDate()) : null;

    if (!lastDay || lastDay.getTime() < today.getTime() - 86400000) {
      this.props.currentStreak = 1;
    } else if (lastDay.getTime() === today.getTime() - 86400000) {
      this.props.currentStreak += 1;
    }
    this.props.lastPlayedDate = now;
  }
}

/* ─── GameSessionEntity ─── */
export interface GameSessionProps {
  childId: string;
  gameType: GameType;
  level?: number;
  completed: boolean;
  score: number;
  timeSpentSeconds: number;
  metrics: Record<string, number>;
  createdAt?: Date;
}

export class GameSessionEntity extends Entity<GameSessionProps> {
  static create(props: Omit<GameSessionProps, 'createdAt'>): GameSessionEntity {
    return new GameSessionEntity(props, Entity.generateId());
  }
  static reconstitute(id: string, props: GameSessionProps): GameSessionEntity { return new GameSessionEntity(props, id); }
  get childId() { return this.props.childId; }
  get gameType() { return this.props.gameType; }
  get level() { return this.props.level; }
  get completed() { return this.props.completed; }
  get score() { return this.props.score; }
  get timeSpentSeconds() { return this.props.timeSpentSeconds; }
  get metrics() { return this.props.metrics; }
  get createdAt() { return this.props.createdAt; }
}
