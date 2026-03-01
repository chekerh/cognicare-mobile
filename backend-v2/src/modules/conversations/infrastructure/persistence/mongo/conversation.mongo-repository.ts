import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { IConversationRepository, IMessageRepository, IConversationSettingRepository } from '../../../domain/repositories/conversation.repository.interface';
import { ConversationEntity, MessageEntity, ConversationSettingEntity } from '../../../domain/entities/conversation.entity';
import {
  ConversationMongoSchema, ConversationDocument,
  MessageMongoSchema, MessageDocument,
  ConversationSettingMongoSchema, ConversationSettingDocument,
} from './conversation.schema';
import { ConversationMapper, MessageMapper, ConversationSettingMapper } from '../../mappers/conversation.mapper';

@Injectable()
export class ConversationMongoRepository implements IConversationRepository {
  constructor(@InjectModel(ConversationMongoSchema.name) private readonly model: Model<ConversationDocument>) {}

  async findByUserId(userId: string): Promise<ConversationEntity[]> {
    const uid = new Types.ObjectId(userId);
    const docs = await this.model.find({ $or: [{ user: uid }, { participants: uid }] }).sort({ updatedAt: -1 }).exec();
    return docs.map(ConversationMapper.toDomain);
  }

  async findById(id: string): Promise<ConversationEntity | null> {
    const doc = await this.model.findById(id).exec();
    return doc ? ConversationMapper.toDomain(doc) : null;
  }

  async findByUserAndOther(userId: string, otherUserId: string): Promise<ConversationEntity | null> {
    const doc = await this.model.findOne({
      user: new Types.ObjectId(userId),
      otherUserId: new Types.ObjectId(otherUserId),
    }).exec();
    return doc ? ConversationMapper.toDomain(doc) : null;
  }

  async save(entity: ConversationEntity): Promise<ConversationEntity> {
    const data = ConversationMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return ConversationMapper.toDomain(saved);
  }

  async update(entity: ConversationEntity): Promise<void> {
    await this.model.findByIdAndUpdate(entity.id, { $set: ConversationMapper.toPersistence(entity) }).exec();
  }

  async delete(id: string): Promise<void> {
    await this.model.findByIdAndDelete(id).exec();
  }
}

@Injectable()
export class MessageMongoRepository implements IMessageRepository {
  constructor(@InjectModel(MessageMongoSchema.name) private readonly model: Model<MessageDocument>) {}

  async findByThreadId(threadId: string): Promise<MessageEntity[]> {
    const docs = await this.model.find({ threadId: new Types.ObjectId(threadId) }).sort({ createdAt: 1 }).exec();
    return docs.map(MessageMapper.toDomain);
  }

  async save(entity: MessageEntity): Promise<MessageEntity> {
    const data = MessageMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return MessageMapper.toDomain(saved);
  }

  async searchByText(threadId: string, query: string): Promise<MessageEntity[]> {
    const docs = await this.model.find({
      threadId: new Types.ObjectId(threadId),
      text: { $regex: query, $options: 'i' },
    }).sort({ createdAt: -1 }).limit(50).exec();
    return docs.map(MessageMapper.toDomain);
  }

  async findMediaByThread(threadId: string): Promise<MessageEntity[]> {
    const docs = await this.model.find({
      threadId: new Types.ObjectId(threadId),
      attachmentUrl: { $exists: true, $ne: null },
    }).sort({ createdAt: -1 }).exec();
    return docs.map(MessageMapper.toDomain);
  }
}

@Injectable()
export class ConversationSettingMongoRepository implements IConversationSettingRepository {
  constructor(@InjectModel(ConversationSettingMongoSchema.name) private readonly model: Model<ConversationSettingDocument>) {}

  async findByUserAndConversation(userId: string, conversationId: string): Promise<ConversationSettingEntity | null> {
    const doc = await this.model.findOne({
      userId: new Types.ObjectId(userId),
      conversationId: new Types.ObjectId(conversationId),
    }).exec();
    return doc ? ConversationSettingMapper.toDomain(doc) : null;
  }

  async save(entity: ConversationSettingEntity): Promise<ConversationSettingEntity> {
    const data = ConversationSettingMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return ConversationSettingMapper.toDomain(saved);
  }

  async update(entity: ConversationSettingEntity): Promise<void> {
    await this.model.findByIdAndUpdate(entity.id, { $set: ConversationSettingMapper.toPersistence(entity) }).exec();
  }
}
