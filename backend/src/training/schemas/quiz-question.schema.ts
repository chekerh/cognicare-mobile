import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

@Schema({ _id: false })
export class QuizQuestion {
  @Prop({ required: true })
  question: string;

  @Prop({ type: [String], required: true })
  options: string[];

  /** Index of the correct option (0-based) */
  @Prop({ required: true })
  correctIndex: number;

  @Prop({ default: 0 })
  order: number;
}

export const QuizQuestionSchema = SchemaFactory.createForClass(QuizQuestion);
