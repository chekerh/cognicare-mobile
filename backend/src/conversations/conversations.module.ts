import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Conversation, ConversationSchema } from './conversation.schema';
import { Message, MessageSchema } from './message.schema';
import {
  ConversationSetting,
  ConversationSettingSchema,
} from './conversation-setting.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { ConversationsService } from './conversations.service';
import { ConversationsController } from './conversations.controller';
import { CallsModule } from '../calls/calls.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Conversation.name, schema: ConversationSchema },
      { name: Message.name, schema: MessageSchema },
      { name: ConversationSetting.name, schema: ConversationSettingSchema },
      { name: User.name, schema: UserSchema },
    ]),
    forwardRef(() => CallsModule),
  ],
  controllers: [ConversationsController],
  providers: [ConversationsService],
  exports: [ConversationsService],
})
export class ConversationsModule {}
