import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  ConversationSchema,
  MessageSchema,
  ConversationSettingSchema,
} from "./infrastructure/persistence/mongo/conversation.schema";
import {
  ConversationMongoRepository,
  MessageMongoRepository,
  ConversationSettingMongoRepository,
} from "./infrastructure/persistence/mongo/conversation.mongo-repository";
import {
  CONVERSATION_REPOSITORY_TOKEN,
  MESSAGE_REPOSITORY_TOKEN,
  CONVERSATION_SETTING_REPOSITORY_TOKEN,
} from "./domain/repositories/conversation.repository.interface";
import {
  GetInboxUseCase,
  GetOrCreateConversationUseCase,
  GetMessagesUseCase,
  SendMessageUseCase,
  DeleteConversationUseCase,
  CreateGroupUseCase,
  AddMemberToGroupUseCase,
  GetSettingsUseCase,
  UpdateSettingsUseCase,
  GetMediaUseCase,
  SearchMessagesUseCase,
  UploadAttachmentUseCase,
} from "./application/use-cases/conversation.use-cases";
import { ConversationsController } from "./interface/http/conversations.controller";

const repos = [
  {
    provide: CONVERSATION_REPOSITORY_TOKEN,
    useClass: ConversationMongoRepository,
  },
  { provide: MESSAGE_REPOSITORY_TOKEN, useClass: MessageMongoRepository },
  {
    provide: CONVERSATION_SETTING_REPOSITORY_TOKEN,
    useClass: ConversationSettingMongoRepository,
  },
];

const useCases = [
  GetInboxUseCase,
  GetOrCreateConversationUseCase,
  GetMessagesUseCase,
  SendMessageUseCase,
  DeleteConversationUseCase,
  CreateGroupUseCase,
  AddMemberToGroupUseCase,
  GetSettingsUseCase,
  UpdateSettingsUseCase,
  GetMediaUseCase,
  SearchMessagesUseCase,
  UploadAttachmentUseCase,
];

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: "Conversation", schema: ConversationSchema },
      { name: "Message", schema: MessageSchema },
      { name: "ConversationSetting", schema: ConversationSettingSchema },
    ]),
  ],
  controllers: [ConversationsController],
  providers: [...repos, ...useCases],
  exports: [CONVERSATION_REPOSITORY_TOKEN, MESSAGE_REPOSITORY_TOKEN],
})
export class ConversationsModule {}
