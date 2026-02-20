import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SpecializedPlanDocument = SpecializedPlan & Document;

@Schema({ timestamps: true })
export class SpecializedPlan {
  @Prop({ type: Types.ObjectId, ref: 'Child', required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  specialistId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Organization' })
  organizationId?: Types.ObjectId;

  @Prop({ required: true, enum: ['PECS', 'TEACCH', 'SkillTracker'] })
  type!: 'PECS' | 'TEACCH' | 'SkillTracker';

  @Prop({ required: true })
  title!: string;

  @Prop({ type: Object })
  content!: any;

  @Prop({ default: 'active', enum: ['active', 'archived'] })
  status!: 'active' | 'archived';

  createdAt?: Date;
  updatedAt?: Date;
}

export const SpecializedPlanSchema =
  SchemaFactory.createForClass(SpecializedPlan);

// Indexes for faster retrieval
SpecializedPlanSchema.index({ childId: 1, type: 1 });
SpecializedPlanSchema.index({ organizationId: 1 });
SpecializedPlanSchema.index({ specialistId: 1 });
