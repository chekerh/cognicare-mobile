import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Conversation,
  ConversationDocument,
  ConversationSegment,
} from './conversation.schema';

@Injectable()
export class ConversationsService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<ConversationDocument>,
  ) {}

  async findInboxForUser(userId: string) {
    const docs = await this.conversationModel
      .find({ user: userId })
      .sort({ updatedAt: -1 })
      .lean()
      .exec();

    return docs.map((c) => ({
      id: c._id.toString(),
      name: c.name,
      subtitle: c.subtitle,
      lastMessage: c.lastMessage,
      timeAgo: c.timeAgo,
      imageUrl: c.imageUrl,
      unread: c.unread,
      segment: c.segment as ConversationSegment,
    }));
  }
}

