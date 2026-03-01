import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

/** Question type: mcq = multiple choice, true_false = T/F (options [True, False]), fill_blank = free text */
export type QuizQuestionType = 'mcq' | 'true_false' | 'fill_blank';

@Schema({ _id: false })
export class QuizQuestion {
  @Prop({ required: true })
  question: string;

  @Prop({ type: [String], default: [] })
  options: string[];

  /** Index of the correct option (0-based). For fill_blank, not used. */
  @Prop({ default: 0 })
  correctIndex: number;

  /** Correct answer text for fill_blank (case-insensitive comparison). */
  @Prop()
  correctAnswer?: string;

  @Prop({ default: 0 })
  order: number;

  /** Optional type; missing = mcq for backward compatibility. */
  @Prop({ enum: ['mcq', 'true_false', 'fill_blank'] })
  type?: QuizQuestionType;
}

export const QuizQuestionSchema = SchemaFactory.createForClass(QuizQuestion);
