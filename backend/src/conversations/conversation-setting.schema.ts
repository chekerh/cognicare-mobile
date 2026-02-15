import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from '../users/schemas/user.schema';

export type ConversationSettingDocument = ConversationSetting & Document;

@Schema({ timestamps: true })
export class ConversationSetting {
  @Prop({ type: Types.ObjectId, ref: User.name, required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, required: true })
  conversationId: Types.ObjectId;

  @Prop({ default: false })
  autoSavePhotos: boolean;

  @Prop({ default: false })
  muted: boolean;
}

export const ConversationSettingSchema =
  SchemaFactory.createForClass(ConversationSetting);

// Index pour retrouver rapidement les paramètres d'un user pour une conversation
ConversationSettingSchema.index(
  { userId: 1, conversationId: 1 },
  { unique: true },
);
