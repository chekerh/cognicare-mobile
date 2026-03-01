import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ConversationMongoSchema, MessageMongoSchema, ConversationSettingMongoSchema,
} from './infrastructure/persistence/mongo/conversation.schema';
import { ConversationMongoRepository, MessageMongoRepository, ConversationSettingMongoRepository } from './infrastructure/persistence/mongo/conversation.mongo-repository';
import {
  GetInboxUseCase, GetOrCreateConversationUseCase, GetMessagesUseCase,
  SendMessageUseCase, DeleteConversationUseCase, CreateGroupUseCase,
  AddMemberToGroupUseCase, GetSettingsUseCase, UpdateSettingsUseCase,
  GetMediaUseCase, SearchMessagesUseCase, UploadAttachmentUseCase,
} from './application/use-cases/conversation.use-cases';
import { ConversationsController } from './interface/http/conversations.controller';

export const CONVERSATION_REPOSITORY_TOKEN = Symbol('IConversationRepository');
export const MESSAGE_REPOSITORY_TOKEN = Symbol('IMessageRepository');
export const CONVERSATION_SETTING_REPOSITORY_TOKEN = Symbol('IConversationSettingRepository');

const repos = [
  { provide: CONVERSATION_REPOSITORY_TOKEN, useClass: ConversationMongoRepository },
  { provide: MESSAGE_REPOSITORY_TOKEN, useClass: MessageMongoRepository },
  { provide: CONVERSATION_SETTING_REPOSITORY_TOKEN, useClass: ConversationSettingMongoRepository },
];

const useCases = [
  GetInboxUseCase, GetOrCreateConversationUseCase, GetMessagesUseCase,
  SendMessageUseCase, DeleteConversationUseCase, CreateGroupUseCase,
  AddMemberToGroupUseCase, GetSettingsUseCase, UpdateSettingsUseCase,
  GetMediaUseCase, SearchMessagesUseCase, UploadAttachmentUseCase,
];

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'Conversation', schema: ConversationMongoSchema },
      { name: 'Message', schema: MessageMongoSchema },
      { name: 'ConversationSetting', schema: ConversationSettingMongoSchema },
    ]),
  ],
  controllers: [ConversationsController],
  providers: [...repos, ...useCases],
  exports: [CONVERSATION_REPOSITORY_TOKEN, MESSAGE_REPOSITORY_TOKEN],
})
export class ConversationsModule {}
