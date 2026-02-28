import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CertificationAttemptDocument = CertificationAttempt & Document;

@Schema({ _id: false })
export class AnswerEntry {
  @Prop({ required: true })
  questionIndex!: number;

  @Prop({ required: true })
  value!: string;
}

export const AnswerEntrySchema = SchemaFactory.createForClass(AnswerEntry);

@Schema({ timestamps: true, collection: 'certificationattempts' })
export class CertificationAttempt {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'CertificationTest' })
  testId?: Types.ObjectId;

  @Prop({ type: [AnswerEntrySchema], required: true })
  answers!: AnswerEntry[];

  @Prop({ required: true })
  scorePercent!: number;

  @Prop({ required: true })
  passed!: boolean;

  /** Set when attempt passed and certification was granted */
  @Prop({ default: false })
  certified?: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CertificationAttemptSchema =
  SchemaFactory.createForClass(CertificationAttempt);
