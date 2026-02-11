import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export type ConversationDocument = Conversation & Document;

export type ConversationSegment = 'persons' | 'families' | 'benevole';

@Schema({ timestamps: true })
export class Conversation {
  @Prop({ type: Types.ObjectId, ref: User.name, required: true })
  user: Types.ObjectId;

  @Prop({ required: true })
  name: string;

  @Prop()
  subtitle?: string;

  @Prop()
  lastMessage: string;

  @Prop()
  timeAgo: string;

  @Prop()
  imageUrl: string;

  @Prop({ default: false })
  unread: boolean;

  @Prop({ enum: ['persons', 'families', 'benevole'], default: 'persons' })
  segment: ConversationSegment;
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);

