import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NotificationMongoSchema } from './infrastructure/persistence/mongo/notification.schema';
import { NotificationMongoRepository } from './infrastructure/persistence/mongo/notification.mongo-repository';
import {
  NOTIFICATION_REPOSITORY_TOKEN,
  ListNotificationsUseCase, CountUnreadUseCase, MarkReadUseCase,
  MarkAllReadUseCase, CreateNotificationUseCase, SyncRoutineRemindersUseCase,
} from './application/use-cases/notification.use-cases';
import { NotificationsController } from './interface/http/notifications.controller';

const useCases = [
  ListNotificationsUseCase, CountUnreadUseCase, MarkReadUseCase,
  MarkAllReadUseCase, CreateNotificationUseCase, SyncRoutineRemindersUseCase,
];

@Module({
  imports: [
    MongooseModule.forFeature([{ name: 'Notification', schema: NotificationMongoSchema }]),
  ],
  controllers: [NotificationsController],
  providers: [
    { provide: NOTIFICATION_REPOSITORY_TOKEN, useClass: NotificationMongoRepository },
    ...useCases,
  ],
  exports: [NOTIFICATION_REPOSITORY_TOKEN, CreateNotificationUseCase],
})
export class NotificationsModule {}
