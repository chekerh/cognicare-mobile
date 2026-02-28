import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type CertificationTestDocument = CertificationTest & Document;

@Schema({ _id: false })
export class CertificationQuestion {
  @Prop({ required: true })
  type!: 'mcq' | 'short_answer';

  @Prop({ required: true })
  text!: string;

  /** For MCQ: list of options (e.g. ['A', 'B', 'C', 'D']) */
  @Prop({ type: [String] })
  options?: string[];

  /** For MCQ: index of the correct option (0-based) */
  @Prop()
  correctOptionIndex?: number;

  /** For short_answer: expected answer (normalized for comparison) */
  @Prop()
  correctAnswer?: string;
}

export const CertificationQuestionSchema =
  SchemaFactory.createForClass(CertificationQuestion);

@Schema({ timestamps: true, collection: 'certificationtests' })
export class CertificationTest {
  @Prop({ default: 'default' })
  slug!: string;

  @Prop()
  title?: string;

  @Prop({ type: [CertificationQuestionSchema], required: true })
  questions!: CertificationQuestion[];

  /** Minimum score (0-100) to pass */
  @Prop({ default: 80 })
  passingScorePercent!: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CertificationTestSchema =
  SchemaFactory.createForClass(CertificationTest);
