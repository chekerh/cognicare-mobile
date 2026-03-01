import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatbotService } from './chatbot.service';
import { ChatbotController } from './chatbot.controller';

// Reuse schemas from their source modules
import { UserSchema } from '@/modules/users/infrastructure/persistence/mongo/user.schema';
import { ChildMongoSchema } from '@/modules/children/infrastructure/persistence/mongo/child.schema';
import { TaskReminderMongoSchema } from '@/modules/nutrition/infrastructure/persistence/mongo/nutrition.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'User', schema: UserSchema },
      { name: 'Child', schema: ChildMongoSchema },
      { name: 'TaskReminder', schema: TaskReminderMongoSchema },
    ]),
  ],
  controllers: [ChatbotController],
  providers: [ChatbotService],
})
export class ChatbotModule {}
