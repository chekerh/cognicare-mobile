import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export type ConversationDocument = Conversation & Document;

export type ConversationSegment =
  | 'persons'
  | 'families'
  | 'benevole'
  | 'healthcare';

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

  @Prop({
    enum: ['persons', 'families', 'benevole', 'healthcare'],
    default: 'persons',
  })
  segment: ConversationSegment;

  /** Links messages; same for both sides of the thread */
  @Prop({ type: Types.ObjectId })
  threadId?: Types.ObjectId;

  /** Other participant (for real messaging) */
  @Prop({ type: Types.ObjectId, ref: User.name })
  otherUserId?: Types.ObjectId;
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);
