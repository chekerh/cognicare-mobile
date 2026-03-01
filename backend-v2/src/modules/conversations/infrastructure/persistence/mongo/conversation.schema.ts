import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ConversationDocument = ConversationMongoSchema & Document;

@Schema({ timestamps: true, collection: 'conversations' })
export class ConversationMongoSchema {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  user!: Types.ObjectId;

  @Prop({ required: true })
  name!: string;

  @Prop()
  subtitle?: string;

  @Prop()
  lastMessage!: string;

  @Prop()
  timeAgo!: string;

  @Prop()
  imageUrl!: string;

  @Prop({ default: false })
  unread!: boolean;

  @Prop({ enum: ['persons', 'families', 'benevole', 'healthcare'], default: 'persons' })
  segment!: string;

  @Prop({ type: Types.ObjectId, index: true })
  threadId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', index: true })
  otherUserId?: Types.ObjectId;

  @Prop({ type: [Types.ObjectId], ref: 'User', index: true })
  participants?: Types.ObjectId[];

  createdAt?: Date;
  updatedAt?: Date;
}

export const ConversationSchema = SchemaFactory.createForClass(ConversationMongoSchema);
ConversationSchema.index({ user: 1, updatedAt: -1 });

export type MessageDocument = MessageMongoSchema & Document;

@Schema({ timestamps: true, collection: 'messages' })
export class MessageMongoSchema {
  @Prop({ type: Types.ObjectId, required: true, index: true })
  threadId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  senderId!: Types.ObjectId;

  @Prop({ required: true })
  text!: string;

  @Prop()
  attachmentUrl?: string;

  @Prop({ enum: ['image', 'voice', 'call_missed', 'call_summary'] })
  attachmentType?: string;

  @Prop()
  callDuration?: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export const MessageSchema = SchemaFactory.createForClass(MessageMongoSchema);

export type ConversationSettingDocument = ConversationSettingMongoSchema & Document;

@Schema({ timestamps: true, collection: 'conversationsettings' })
export class ConversationSettingMongoSchema {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true })
  conversationId!: Types.ObjectId;

  @Prop({ default: false })
  autoSavePhotos!: boolean;

  @Prop({ default: false })
  muted!: boolean;
}

export const ConversationSettingSchema = SchemaFactory.createForClass(ConversationSettingMongoSchema);
ConversationSettingSchema.index({ userId: 1, conversationId: 1 }, { unique: true });
