import { Types } from "mongoose";
import {
  ConversationEntity,
  MessageEntity,
  ConversationSettingEntity,
  ConversationSegment,
  AttachmentType,
} from "../../domain/entities/conversation.entity";
import {
  ConversationDocument,
  MessageDocument,
  ConversationSettingDocument,
} from "../persistence/mongo/conversation.schema";

export class ConversationMapper {
  static toDomain(doc: ConversationDocument): ConversationEntity {
    return ConversationEntity.reconstitute(doc._id.toString(), {
      userId: doc.user.toString(),
      name: doc.name,
      subtitle: doc.subtitle,
      lastMessage: doc.lastMessage,
      timeAgo: doc.timeAgo,
      imageUrl: doc.imageUrl,
      unread: doc.unread,
      segment: doc.segment as ConversationSegment,
      threadId: doc.threadId?.toString(),
      otherUserId: doc.otherUserId?.toString(),
      participants: doc.participants?.map((p) => p.toString()),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }
  static toPersistence(entity: ConversationEntity): Record<string, unknown> {
    return {
      user: new Types.ObjectId(entity.userId),
      name: entity.name,
      subtitle: entity.subtitle,
      lastMessage: entity.lastMessage,
      timeAgo: entity.timeAgo,
      imageUrl: entity.imageUrl,
      unread: entity.unread,
      segment: entity.segment,
      threadId: entity.threadId
        ? new Types.ObjectId(entity.threadId)
        : undefined,
      otherUserId: entity.otherUserId
        ? new Types.ObjectId(entity.otherUserId)
        : undefined,
      participants: entity.participants?.map((p) => new Types.ObjectId(p)),
    };
  }
}

export class MessageMapper {
  static toDomain(doc: MessageDocument): MessageEntity {
    return MessageEntity.reconstitute(doc._id.toString(), {
      threadId: doc.threadId.toString(),
      senderId: doc.senderId.toString(),
      text: doc.text,
      attachmentUrl: doc.attachmentUrl,
      attachmentType: doc.attachmentType as AttachmentType | undefined,
      callDuration: doc.callDuration,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }
  static toPersistence(entity: MessageEntity): Record<string, unknown> {
    return {
      threadId: new Types.ObjectId(entity.threadId),
      senderId: new Types.ObjectId(entity.senderId),
      text: entity.text,
      attachmentUrl: entity.attachmentUrl,
      attachmentType: entity.attachmentType,
      callDuration: entity.callDuration,
    };
  }
}

export class ConversationSettingMapper {
  static toDomain(doc: ConversationSettingDocument): ConversationSettingEntity {
    return ConversationSettingEntity.reconstitute(doc._id.toString(), {
      userId: doc.userId.toString(),
      conversationId: doc.conversationId.toString(),
      autoSavePhotos: doc.autoSavePhotos,
      muted: doc.muted,
    });
  }
  static toPersistence(
    entity: ConversationSettingEntity,
  ): Record<string, unknown> {
    return {
      userId: new Types.ObjectId(entity.userId),
      conversationId: new Types.ObjectId(entity.conversationId),
      autoSavePhotos: entity.autoSavePhotos,
      muted: entity.muted,
    };
  }
}
