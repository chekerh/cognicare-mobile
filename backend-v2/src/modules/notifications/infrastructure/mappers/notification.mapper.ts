import { Types } from 'mongoose';
import { NotificationEntity } from '../../domain/entities/notification.entity';

export class NotificationMapper {
  static toDomain(raw: Record<string, any>): NotificationEntity {
    return NotificationEntity.reconstitute(raw._id.toString(), {
      userId: raw.userId?.toString() ?? '',
      type: raw.type ?? '',
      title: raw.title ?? '',
      description: raw.description ?? '',
      read: raw.read ?? false,
      data: raw.data ?? undefined,
      createdAt: raw.createdAt,
      updatedAt: raw.updatedAt,
    });
  }

  static toPersistence(entity: NotificationEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(entity.id),
      userId: new Types.ObjectId(entity.userId),
      type: entity.type,
      title: entity.title,
      description: entity.description,
      read: entity.read,
      data: entity.data ?? null,
    };
  }
}
