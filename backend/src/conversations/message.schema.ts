import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export type MessageDocument = Message & Document;

@Schema({ timestamps: true })
export class Message {
  @Prop({ type: Types.ObjectId, required: true, index: true })
  threadId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: User.name, required: true })
  senderId: Types.ObjectId;

  @Prop({ required: true })
  text: string;

  @Prop()
  attachmentUrl?: string;

  @Prop({ enum: ['image', 'voice', 'call_missed', 'call_summary'] })
  attachmentType?: 'image' | 'voice' | 'call_missed' | 'call_summary';

  @Prop()
  callDuration?: number;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
