import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatbotController } from './chatbot.controller';
import { ChatbotService } from './chatbot.service';
import { User, UserSchema } from '../users/schemas/user.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import { TaskReminder, TaskReminderSchema } from '../nutrition/schemas/task-reminder.schema';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema },
            { name: Child.name, schema: ChildSchema },
            { name: TaskReminder.name, schema: TaskReminderSchema },
        ]),
    ],
    controllers: [ChatbotController],
    providers: [ChatbotService],
})
export class ChatbotModule { }
