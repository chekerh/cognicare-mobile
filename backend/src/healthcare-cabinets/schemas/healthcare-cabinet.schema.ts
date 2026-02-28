import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type HealthcareCabinetDocument = HealthcareCabinet & Document;

@Schema({ timestamps: true })
export class HealthcareCabinet {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  specialty: string; // Orthophoniste, Pédopsychiatre, Psychologue, Ergothérapeute, Centre autisme, etc.

  @Prop({ default: '' })
  address: string;

  @Prop({ required: true })
  city: string;

  @Prop({ required: true })
  latitude: number;

  @Prop({ required: true })
  longitude: number;

  @Prop()
  phone?: string;

  @Prop()
  website?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const HealthcareCabinetSchema =
  SchemaFactory.createForClass(HealthcareCabinet);
