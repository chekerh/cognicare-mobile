import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type NutritionPlanDocument = NutritionPlan & Document;

@Schema({ timestamps: true })
export class NutritionPlan {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdBy!: Types.ObjectId; // Parent or healthcare professional

  // Hydration
  @Prop({ default: 6 }) // Default: 6 glasses of water per day
  dailyWaterGoal!: number;

  @Prop({ default: 120 }) // Default: remind every 2 hours (120 minutes)
  waterReminderInterval!: number; // in minutes

  // Meals
  @Prop({ type: [String], default: [] })
  breakfast?: string[]; // List of food items

  @Prop() // e.g., "8:00 AM"
  breakfastTime?: string;

  @Prop({ type: [String], default: [] })
  lunch?: string[];

  @Prop()
  lunchTime?: string;

  @Prop({ type: [String], default: [] })
  dinner?: string[];

  @Prop()
  dinnerTime?: string;

  @Prop({ type: [{ time: String, items: [String] }], default: [] })
  snacks?: Array<{ time: string; items: string[] }>;

  // Dietary restrictions
  @Prop({ type: [String], default: [] })
  allergies?: string[];

  @Prop({ type: [String], default: [] })
  restrictions?: string[]; // e.g., "gluten-free", "lactose-free"

  @Prop({ type: [String], default: [] })
  preferences?: string[]; // e.g., "vegetarian", "likes fruits"

  // Medications & Supplements
  @Prop({
    type: [
      {
        name: String,
        dosage: String,
        time: String,
        withFood: { type: Boolean, default: false },
        notes: String,
      },
    ],
    default: [],
  })
  medications?: Array<{
    name: string;
    dosage: string;
    time: string;
    withFood?: boolean;
    notes?: string;
  }>;

  // Notes
  @Prop()
  specialNotes?: string;

  @Prop({ default: true })
  isActive!: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const NutritionPlanSchema = SchemaFactory.createForClass(NutritionPlan);
