import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TaskReminderDocument = TaskReminder & Document;

export enum ReminderType {
  WATER = 'water',
  MEAL = 'meal',
  MEDICATION = 'medication',
  HOMEWORK = 'homework',
  ACTIVITY = 'activity',
  HYGIENE = 'hygiene',
  CUSTOM = 'custom',
}

export enum ReminderFrequency {
  ONCE = 'once', // One-time reminder
  DAILY = 'daily',
  WEEKLY = 'weekly',
  INTERVAL = 'interval', // Every X minutes/hours
}

@Schema({ timestamps: true })
export class TaskReminder {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdBy!: Types.ObjectId; // Parent or healthcare professional

  @Prop({
    required: true,
    enum: Object.values(ReminderType),
  })
  type!: ReminderType;

  @Prop({ required: true })
  title!: string; // e.g., "Drink Water", "Take Medicine", "Brush Teeth"

  @Prop()
  description?: string;

  @Prop() // Icon name or emoji
  icon?: string;

  @Prop() // Color hex code
  color?: string;

  // Scheduling
  @Prop({
    required: true,
    enum: Object.values(ReminderFrequency),
  })
  frequency!: ReminderFrequency;

  @Prop() // For specific time reminders (e.g., "08:00", "14:30")
  time?: string;

  @Prop() // For interval reminders (in minutes)
  intervalMinutes?: number;

  @Prop({ type: [String], default: [] }) // Days of week: ["monday", "tuesday", ...]
  daysOfWeek?: string[];

  // Notification settings
  @Prop({ default: true })
  soundEnabled!: boolean;

  @Prop({ default: true })
  vibrationEnabled!: boolean;

  @Prop({ default: false })
  piSyncEnabled!: boolean; // Sync with Raspberry Pi for physical reminders

  // Completion tracking
  @Prop({
    type: [
      {
        date: Date,
        completed: Boolean,
        completedAt: Date,
        proofImageUrl: String,
        verificationStatus: {
          type: String,
          enum: ['PENDING', 'VALID', 'UNCERTAIN', 'INVALID'],
          default: 'PENDING'
        },
        verificationMetadata: {
          medicineName: String,
          dosage: String,
          expiryDate: String,
          reasoning: String
        }
      },
    ],
    default: [],
  })
  completionHistory?: Array<{
    date: Date;
    completed: boolean;
    completedAt?: Date;
    proofImageUrl?: string;
    verificationStatus?: 'PENDING' | 'VALID' | 'UNCERTAIN' | 'INVALID';
    verificationMetadata?: {
      medicineName?: string;
      dosage?: string;
      expiryDate?: string;
      reasoning?: string;
    };
  }>;

  @Prop({ default: true })
  isActive!: boolean;

  @Prop()
  linkedNutritionPlanId?: Types.ObjectId; // Link to nutrition plan if applicable

  createdAt?: Date;
  updatedAt?: Date;
}

export const TaskReminderSchema = SchemaFactory.createForClass(TaskReminder);
