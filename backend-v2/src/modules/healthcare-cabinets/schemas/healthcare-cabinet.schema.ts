import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type HealthcareCabinetDocument = HealthcareCabinet & Document;

@Schema({ timestamps: true })
export class HealthcareCabinet {
  @Prop({ unique: true, sparse: true }) placeId?: string;
  @Prop({ required: true }) name!: string;
  @Prop({ required: true }) specialty!: string;
  @Prop({ default: "" }) address!: string;
  @Prop({ required: true }) city!: string;
  @Prop({ required: true }) latitude!: number;
  @Prop({ required: true }) longitude!: number;
  @Prop() phone?: string;
  @Prop() website?: string;
  createdAt?: Date;
  updatedAt?: Date;
}
export const HealthcareCabinetSchema =
  SchemaFactory.createForClass(HealthcareCabinet);
