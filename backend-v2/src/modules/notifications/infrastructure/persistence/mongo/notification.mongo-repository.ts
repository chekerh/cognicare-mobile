import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { INotificationRepository } from '../../../domain/repositories/notification.repository.interface';
import { NotificationEntity } from '../../../domain/entities/notification.entity';
import { NotificationMapper } from '../../mappers/notification.mapper';

@Injectable()
export class NotificationMongoRepository implements INotificationRepository {
  constructor(@InjectModel('Notification') private readonly model: Model<any>) {}

  async findByUserId(userId: string, limit = 50): Promise<NotificationEntity[]> {
    const docs = await this.model
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean()
      .exec();
    return docs.map(NotificationMapper.toDomain);
  }

  async countUnread(userId: string): Promise<number> {
    return this.model.countDocuments({ userId: new Types.ObjectId(userId), read: false }).exec();
  }

  async findById(id: string): Promise<NotificationEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).lean().exec();
    return doc ? NotificationMapper.toDomain(doc) : null;
  }

  async save(entity: NotificationEntity): Promise<NotificationEntity> {
    const data = NotificationMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return NotificationMapper.toDomain(doc.toObject());
  }

  async markRead(userId: string, id: string): Promise<boolean> {
    const result = await this.model
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), userId: new Types.ObjectId(userId) },
        { $set: { read: true } },
      )
      .exec();
    return !!result;
  }

  async markAllRead(userId: string): Promise<void> {
    await this.model
      .updateMany({ userId: new Types.ObjectId(userId) }, { $set: { read: true } })
      .exec();
  }

  async findByUserAndData(userId: string, filter: Record<string, unknown>): Promise<NotificationEntity | null> {
    const query: Record<string, unknown> = { userId: new Types.ObjectId(userId) };
    for (const [key, val] of Object.entries(filter)) {
      query[`data.${key}`] = val;
    }
    const doc = await this.model.findOne(query).lean().exec();
    return doc ? NotificationMapper.toDomain(doc) : null;
  }
}
