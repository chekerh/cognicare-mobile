import { Inject, Injectable } from '@nestjs/common';
import { Result, ok, err } from '../../../../core/result';
import { INotificationRepository } from '../../domain/repositories/notification.repository.interface';
import { NotificationEntity } from '../../domain/entities/notification.entity';
import { NotificationOutputDto } from '../dto/notification.dto';

export const NOTIFICATION_REPOSITORY_TOKEN = Symbol('INotificationRepository');

function toOutput(e: NotificationEntity): NotificationOutputDto {
  return {
    id: e.id,
    type: e.type,
    title: e.title,
    description: e.description,
    read: e.read,
    data: e.data,
    createdAt: e.createdAt?.toISOString(),
  };
}

@Injectable()
export class ListNotificationsUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}
  async execute(userId: string, limit?: number): Promise<Result<NotificationOutputDto[], string>> {
    const list = await this.repo.findByUserId(userId, limit);
    return ok(list.map(toOutput));
  }
}

@Injectable()
export class CountUnreadUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}
  async execute(userId: string): Promise<Result<number, string>> {
    return ok(await this.repo.countUnread(userId));
  }
}

@Injectable()
export class MarkReadUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}
  async execute(userId: string, notificationId: string): Promise<Result<boolean, string>> {
    const found = await this.repo.markRead(userId, notificationId);
    if (!found) return err('Notification not found');
    return ok(true);
  }
}

@Injectable()
export class MarkAllReadUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}
  async execute(userId: string): Promise<Result<boolean, string>> {
    await this.repo.markAllRead(userId);
    return ok(true);
  }
}

@Injectable()
export class CreateNotificationUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}
  async execute(userId: string, payload: { type: string; title: string; description?: string; data?: Record<string, unknown> }): Promise<Result<NotificationOutputDto, string>> {
    const entity = NotificationEntity.create({
      userId,
      type: payload.type,
      title: payload.title,
      description: payload.description ?? '',
      data: payload.data,
    });
    const saved = await this.repo.save(entity);
    return ok(toOutput(saved));
  }
}

@Injectable()
export class SyncRoutineRemindersUseCase {
  constructor(@Inject(NOTIFICATION_REPOSITORY_TOKEN) private readonly repo: INotificationRepository) {}

  /**
   * This use case will be wired to children + reminders repos later.
   * For now it's a placeholder matching the old service interface.
   */
  async execute(_userId: string): Promise<Result<void, string>> {
    // TODO: inject children repo + reminders repo to replicate syncRoutineReminders logic
    return ok(undefined);
  }
}
