import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ChildDocument = Child & Document;

@Schema({ timestamps: true })
export class Child {
  @Prop({ required: true })
  fullName!: string;

  @Prop({ required: true })
  dateOfBirth!: Date;

  @Prop({
    required: true,
    enum: ['male', 'female', 'other'],
  })
  gender!: 'male' | 'female' | 'other';

  @Prop()
  diagnosis?: string;

  @Prop()
  medicalHistory?: string;

  @Prop()
  allergies?: string;

  @Prop()
  medications?: string;

  @Prop()
  notes?: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  parentId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Organization' })
  organizationId?: Types.ObjectId;

  @Prop()
  profilePic?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ChildSchema = SchemaFactory.createForClass(Child);
