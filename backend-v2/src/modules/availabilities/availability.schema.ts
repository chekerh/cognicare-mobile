import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type AvailabilityDocument = Availability & Document;

@Schema({ timestamps: true })
export class Availability {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  volunteerId!: Types.ObjectId;

  @Prop({ type: [String], required: true })
  dates!: string[];

  @Prop({ default: "14:00" })
  startTime!: string;

  @Prop({ default: "18:00" })
  endTime!: string;

  @Prop({ default: "weekly" })
  recurrence!: string;

  @Prop({ default: true })
  recurrenceOn!: boolean;
}

export const AvailabilitySchema = SchemaFactory.createForClass(Availability);
