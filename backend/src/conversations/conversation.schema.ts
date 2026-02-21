import { Prop, Schema, SchemaFactory, index } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export type ConversationDocument = Conversation & Document;

export type ConversationSegment =
  | 'persons'
  | 'families'
  | 'benevole'
  | 'healthcare';

@Schema({ timestamps: true })
@index({ user: 1, updatedAt: -1 })
@index({ otherUserId: 1, updatedAt: -1 })
export class Conversation {
  @Prop({ type: Types.ObjectId, ref: User.name, required: true, index: true })
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
  @Prop({ type: Types.ObjectId, index: true })
  threadId?: Types.ObjectId;

  /** Other participant (for 1-1 messaging) */
  @Prop({ type: Types.ObjectId, ref: User.name, index: true })
  otherUserId?: Types.ObjectId;

  /** For group conversations: all participant user ids (including creator) */
  @Prop({ type: [Types.ObjectId], ref: User.name, index: true })
  participants?: Types.ObjectId[];
}

export const ConversationSchema = SchemaFactory.createForClass(Conversation);
