import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Notification,
  NotificationDocument,
} from './schemas/notification.schema';

export type NotificationLean = Notification & { _id: Types.ObjectId };

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name)
    private readonly notificationModel: Model<NotificationDocument>,
  ) {}

  async listForUser(userId: string, limit = 50): Promise<NotificationLean[]> {
    const list = await this.notificationModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean()
      .exec();
    return list as NotificationLean[];
  }

  async countUnread(userId: string): Promise<number> {
    return this.notificationModel
      .countDocuments({
        userId: new Types.ObjectId(userId),
        read: false,
      })
      .exec();
  }

  async markRead(userId: string, notificationId: string): Promise<void> {
    const updated = await this.notificationModel
      .findOneAndUpdate(
        {
          _id: new Types.ObjectId(notificationId),
          userId: new Types.ObjectId(userId),
        },
        { $set: { read: true } },
      )
      .exec();
    if (!updated) throw new NotFoundException('Notification not found');
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notificationModel
      .updateMany(
        { userId: new Types.ObjectId(userId) },
        { $set: { read: true } },
      )
      .exec();
  }

  async createForUser(
    userId: string,
    payload: {
      type: string;
      title: string;
      description?: string;
      data?: Record<string, unknown>;
    },
  ): Promise<NotificationLean> {
    const doc = await this.notificationModel.create({
      userId: new Types.ObjectId(userId),
      type: payload.type,
      title: payload.title,
      description: payload.description ?? '',
      read: false,
      data: payload.data ?? undefined,
    });
    return doc.toObject() as NotificationLean;
  }
}
