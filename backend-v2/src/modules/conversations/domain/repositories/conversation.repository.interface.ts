import { ConversationEntity, MessageEntity, ConversationSettingEntity } from '../entities/conversation.entity';

export const CONVERSATION_REPOSITORY_TOKEN = Symbol('IConversationRepository');
export const MESSAGE_REPOSITORY_TOKEN = Symbol('IMessageRepository');
export const CONVERSATION_SETTING_REPOSITORY_TOKEN = Symbol('IConversationSettingRepository');

export interface IConversationRepository {
  findByUserId(userId: string): Promise<ConversationEntity[]>;
  findById(id: string): Promise<ConversationEntity | null>;
  findByUserAndOther(userId: string, otherUserId: string): Promise<ConversationEntity | null>;
  save(entity: ConversationEntity): Promise<ConversationEntity>;
  update(entity: ConversationEntity): Promise<void>;
  delete(id: string): Promise<void>;
}

export interface IMessageRepository {
  findByThreadId(threadId: string): Promise<MessageEntity[]>;
  save(entity: MessageEntity): Promise<MessageEntity>;
  searchByText(threadId: string, query: string): Promise<MessageEntity[]>;
  findMediaByThread(threadId: string): Promise<MessageEntity[]>;
}

export interface IConversationSettingRepository {
  findByUserAndConversation(userId: string, conversationId: string): Promise<ConversationSettingEntity | null>;
  save(entity: ConversationSettingEntity): Promise<ConversationSettingEntity>;
  update(entity: ConversationSettingEntity): Promise<void>;
}
