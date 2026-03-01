import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ParentFeedbackRequestDocument = ParentFeedbackRequest & Document;

@Schema({ timestamps: true })
export class ParentFeedbackRequest {
  @Prop({ type: Types.ObjectId, ref: "ChildMongoSchema", required: true })
  childId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "UserMongoSchema", required: true })
  specialistId!: Types.ObjectId;

  @Prop()
  recommendationId?: string;

  @Prop()
  planType?: string;

  @Prop()
  message?: string;

  @Prop({ default: "pending", enum: ["pending", "answered"] })
  status!: "pending" | "answered";

  createdAt?: Date;
  updatedAt?: Date;
}

export const ParentFeedbackRequestSchema = SchemaFactory.createForClass(
  ParentFeedbackRequest,
);

ParentFeedbackRequestSchema.index({ childId: 1, status: 1 });
