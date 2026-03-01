import { Schema, Types } from 'mongoose';

export const BadgeMongoSchema = new Schema(
  {
    badgeId: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    description: String,
    type: { type: String, enum: ['games_completed', 'points_milestone', 'streak', 'game_specific', 'weekly_challenge'], required: true },
    iconUrl: String,
    requirements: { type: Map, of: Number, default: {} },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

export const ChildBadgeMongoSchema = new Schema(
  {
    childId: { type: Types.ObjectId, ref: 'Child', required: true },
    badgeId: { type: Types.ObjectId, ref: 'Badge', required: true },
    badgeIdString: { type: String, required: true },
    earnedAt: { type: Date, default: Date.now },
    gameType: String,
  },
  { timestamps: true },
);
ChildBadgeMongoSchema.index({ childId: 1, badgeIdString: 1 }, { unique: true });

export const PointsMongoSchema = new Schema(
  {
    childId: { type: Types.ObjectId, ref: 'Child', required: true },
    totalPoints: { type: Number, default: 0 },
    pointsByGame: { type: Map, of: Number, default: {} },
    gamesPlayed: { type: [String], default: [] },
    gamesCompleted: { type: Number, default: 0 },
    currentStreak: { type: Number, default: 0 },
    lastPlayedDate: Date,
  },
  { timestamps: true },
);
PointsMongoSchema.index({ childId: 1 }, { unique: true });

export const GameSessionMongoSchema = new Schema(
  {
    childId: { type: Types.ObjectId, ref: 'Child', required: true },
    gameType: { type: String, enum: ['matching', 'shape_sorting', 'star_tracer', 'basket_sort', 'child_mode'], required: true },
    level: Number,
    completed: { type: Boolean, default: false },
    score: { type: Number, default: 0 },
    timeSpentSeconds: { type: Number, default: 0 },
    metrics: { type: Map, of: Number, default: {} },
  },
  { timestamps: true },
);
GameSessionMongoSchema.index({ childId: 1, createdAt: -1 });
