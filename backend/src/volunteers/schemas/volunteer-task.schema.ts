import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type VolunteerTaskDocument = VolunteerTask & Document;

@Schema({ timestamps: true, collection: 'volunteertasks' })
export class VolunteerTask {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  assignedBy!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  volunteerId!: Types.ObjectId;

  @Prop({ required: true })
  title!: string;

  @Prop({ default: '' })
  description!: string;

  @Prop({ default: 'pending', enum: ['pending', 'accepted', 'completed', 'cancelled'] })
  status!: string;

  @Prop()
  dueDate?: Date;

  @Prop()
  completedAt?: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const VolunteerTaskSchema = SchemaFactory.createForClass(VolunteerTask);
VolunteerTaskSchema.index({ volunteerId: 1, createdAt: -1 });
VolunteerTaskSchema.index({ assignedBy: 1 });
