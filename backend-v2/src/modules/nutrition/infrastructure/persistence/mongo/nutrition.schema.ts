import { Schema, Types } from 'mongoose';

export const NutritionPlanMongoSchema = new Schema(
  {
    childId: { type: Types.ObjectId, ref: 'Child', required: true },
    createdBy: { type: Types.ObjectId, ref: 'User', required: true },
    dailyWaterGoal: { type: Number, default: 6 },
    waterReminderInterval: { type: Number, default: 120 },
    breakfast: { type: [String], default: [] },
    breakfastTime: String,
    lunch: { type: [String], default: [] },
    lunchTime: String,
    dinner: { type: [String], default: [] },
    dinnerTime: String,
    snacks: { type: [{ time: String, items: [String] }], default: [] },
    allergies: { type: [String], default: [] },
    restrictions: { type: [String], default: [] },
    preferences: { type: [String], default: [] },
    medications: {
      type: [{
        name: String,
        dosage: String,
        time: String,
        withFood: { type: Boolean, default: false },
        notes: String,
      }],
      default: [],
    },
    specialNotes: String,
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);
NutritionPlanMongoSchema.index({ childId: 1, isActive: 1 });

export const TaskReminderMongoSchema = new Schema(
  {
    childId: { type: Types.ObjectId, ref: 'Child', required: true },
    createdBy: { type: Types.ObjectId, ref: 'User', required: true },
    type: { type: String, required: true, enum: ['water', 'meal', 'medication', 'homework', 'activity', 'hygiene', 'custom'] },
    title: { type: String, required: true },
    description: String,
    icon: String,
    color: String,
    frequency: { type: String, required: true, enum: ['once', 'daily', 'weekly', 'interval'] },
    times: { type: [String], default: [] },
    intervalMinutes: Number,
    daysOfWeek: { type: [String], default: [] },
    soundEnabled: { type: Boolean, default: true },
    vibrationEnabled: { type: Boolean, default: true },
    completionHistory: {
      type: [{
        date: Date,
        completed: Boolean,
        completedAt: Date,
        feedback: String,
        proofImageUrl: String,
        verificationStatus: { type: String, enum: ['PENDING', 'VALID', 'UNCERTAIN', 'INVALID'], default: 'PENDING' },
        verificationMetadata: Schema.Types.Mixed,
      }],
      default: [],
    },
    isActive: { type: Boolean, default: true },
    linkedNutritionPlanId: { type: Types.ObjectId },
  },
  { timestamps: true },
);
TaskReminderMongoSchema.index({ childId: 1, isActive: 1 });
