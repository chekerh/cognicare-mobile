import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Conversation,
  ConversationDocument,
  ConversationSegment,
} from './conversation.schema';
import { Message, MessageDocument } from './message.schema';

@Injectable()
export class ConversationsService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name)
    private readonly messageModel: Model<MessageDocument>,
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

  /** Get or create a conversation between current user and otherUserId. Returns conversation for current user. */
  async getOrCreateConversation(
    userId: string,
    otherUserId: string,
    options?: { name?: string; imageUrl?: string; segment?: ConversationSegment },
  ) {
    const uid = new Types.ObjectId(userId);
    const oid = new Types.ObjectId(otherUserId);
    let conv = await this.conversationModel
      .findOne({
        user: uid,
        otherUserId: oid,
      })
      .lean()
      .exec();

    if (conv) {
      return {
        id: conv._id.toString(),
        threadId: conv.threadId?.toString(),
        name: conv.name,
        subtitle: conv.subtitle,
        lastMessage: conv.lastMessage,
        timeAgo: conv.timeAgo,
        imageUrl: conv.imageUrl,
        unread: conv.unread,
        segment: conv.segment,
      };
    }

    const threadId = new Types.ObjectId();
    const [created] = await this.conversationModel.create([
      {
        user: uid,
        otherUserId: oid,
        threadId,
        name: options?.name ?? 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: options?.imageUrl ?? '',
        segment: options?.segment ?? 'persons',
      },
      {
        user: oid,
        otherUserId: uid,
        threadId,
        name: options?.name ?? 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: options?.imageUrl ?? '',
        segment: options?.segment ?? 'persons',
      },
    ]);

    return {
      id: created._id.toString(),
      threadId: created.threadId?.toString(),
      name: created.name,
      subtitle: created.subtitle,
      lastMessage: created.lastMessage,
      timeAgo: created.timeAgo,
      imageUrl: created.imageUrl,
      unread: created.unread,
      segment: created.segment,
    };
  }

  async getMessages(conversationId: string, userId: string) {
    const conv = await this.conversationModel
      .findById(conversationId)
      .lean()
      .exec();
    if (!conv) throw new NotFoundException('Conversation not found');
    const uid = new Types.ObjectId(userId);
    if (!conv.user.equals(uid) && !conv.otherUserId?.equals(uid)) {
      throw new ForbiddenException('Not a participant');
    }
    const threadId = conv.threadId ?? conv._id;
    const messages = await this.messageModel
      .find({ threadId })
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    return messages.map((m) => ({
      id: m._id.toString(),
      senderId: m.senderId.toString(),
      text: m.text,
      createdAt: (m as any).createdAt,
    }));
  }

  async addMessage(conversationId: string, userId: string, text: string) {
    const conv = await this.conversationModel.findById(conversationId).exec();
    if (!conv) throw new NotFoundException('Conversation not found');
    const uid = new Types.ObjectId(userId);
    if (!conv.user.equals(uid) && !conv.otherUserId?.equals(uid)) {
      throw new ForbiddenException('Not a participant');
    }
    const threadId = conv.threadId ?? conv._id;
    const created = await this.messageModel.create({
      threadId,
      senderId: uid,
      text,
    });
    const timeAgo = formatTimeAgo(new Date());
    await this.conversationModel
      .updateMany(
        { $or: [{ _id: conv._id }, { threadId }] },
        { lastMessage: text, timeAgo, updatedAt: new Date() },
      )
      .exec();
    return {
      id: created._id.toString(),
      senderId: created.senderId.toString(),
      text: created.text,
      createdAt: (created as any).createdAt,
    };
  }
}

function formatTimeAgo(d: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const diffM = Math.floor(diffMs / 60000);
  if (diffM < 1) return "À l'instant";
  if (diffM < 60) return `Il y a ${diffM} min`;
  const diffH = Math.floor(diffM / 60);
  if (diffH < 24) return `Il y a ${diffH}h`;
  const diffD = Math.floor(diffH / 24);
  return `Il y a ${diffD}j`;
}

