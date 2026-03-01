import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

// ── Sub-schemas ──

export type CertificationTestDocument = CertificationTest & Document;

@Schema({ _id: false })
export class CertificationQuestion {
  @Prop({ required: true }) type!: "mcq" | "short_answer";
  @Prop({ required: true }) text!: string;
  @Prop({ type: [String] }) options?: string[];
  @Prop() correctOptionIndex?: number;
  @Prop() correctAnswer?: string;
}
export const CertificationQuestionSchema = SchemaFactory.createForClass(
  CertificationQuestion,
);

@Schema({ timestamps: true, collection: "certificationtests" })
export class CertificationTest {
  @Prop({ default: "default" }) slug!: string;
  @Prop() title?: string;
  @Prop({ type: [CertificationQuestionSchema], required: true })
  questions!: CertificationQuestion[];
  @Prop({ default: 80 }) passingScorePercent!: number;
  createdAt?: Date;
  updatedAt?: Date;
}
export const CertificationTestSchema =
  SchemaFactory.createForClass(CertificationTest);

// ── Attempt ──

export type CertificationAttemptDocument = CertificationAttempt & Document;

@Schema({ _id: false })
export class AnswerEntry {
  @Prop({ required: true }) questionIndex!: number;
  @Prop({ required: true }) value!: string;
}
export const AnswerEntrySchema = SchemaFactory.createForClass(AnswerEntry);

@Schema({ timestamps: true, collection: "certificationattempts" })
export class CertificationAttempt {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  userId!: Types.ObjectId;
  @Prop({ type: Types.ObjectId, ref: "CertificationTest" })
  testId?: Types.ObjectId;
  @Prop({ type: [AnswerEntrySchema], required: true }) answers!: AnswerEntry[];
  @Prop({ required: true }) scorePercent!: number;
  @Prop({ required: true }) passed!: boolean;
  @Prop({ default: false }) certified?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}
export const CertificationAttemptSchema =
  SchemaFactory.createForClass(CertificationAttempt);
