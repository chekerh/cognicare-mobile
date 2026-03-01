import { NotificationEntity } from '../entities/notification.entity';

export interface INotificationRepository {
  findByUserId(userId: string, limit?: number): Promise<NotificationEntity[]>;
  countUnread(userId: string): Promise<number>;
  findById(id: string): Promise<NotificationEntity | null>;
  save(entity: NotificationEntity): Promise<NotificationEntity>;
  markRead(userId: string, id: string): Promise<boolean>;
  markAllRead(userId: string): Promise<void>;
  findByUserAndData(userId: string, filter: Record<string, unknown>): Promise<NotificationEntity | null>;
}
