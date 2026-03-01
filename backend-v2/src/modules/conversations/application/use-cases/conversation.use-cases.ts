import { Inject, Injectable } from '@nestjs/common';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok, err } from '../../../../core/application/result';
import {
  CONVERSATION_REPOSITORY_TOKEN, IConversationRepository,
  MESSAGE_REPOSITORY_TOKEN, IMessageRepository,
  CONVERSATION_SETTING_REPOSITORY_TOKEN, IConversationSettingRepository,
} from '../../domain/repositories/conversation.repository.interface';
import { ConversationEntity, MessageEntity, ConversationSettingEntity, AttachmentType } from '../../domain/entities/conversation.entity';
import { Entity } from '../../../../core/domain/entity.base';

// ── Get Inbox ──
@Injectable()
export class GetInboxUseCase implements IUseCase<string, Result<any[], string>> {
  constructor(@Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly repo: IConversationRepository) {}
  async execute(userId: string): Promise<Result<any[], string>> {
    const convs = await this.repo.findByUserId(userId);
    return ok(convs.map((c) => c.toObject()));
  }
}

// ── Get or Create Conversation ──
@Injectable()
export class GetOrCreateConversationUseCase implements IUseCase<{ userId: string; otherUserId: string; userName: string; otherName: string }, Result<any, string>> {
  constructor(@Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly repo: IConversationRepository) {}
  async execute(input: { userId: string; otherUserId: string; userName: string; otherName: string }): Promise<Result<any, string>> {
    let conv = await this.repo.findByUserAndOther(input.userId, input.otherUserId);
    if (conv) return ok(conv.toObject());

    const threadId = Entity.generateId();
    const conv1 = ConversationEntity.create({
      userId: input.userId, name: input.otherName, lastMessage: '', timeAgo: '',
      imageUrl: '', unread: false, segment: 'persons',
      threadId, otherUserId: input.otherUserId,
    });
    const conv2 = ConversationEntity.create({
      userId: input.otherUserId, name: input.userName, lastMessage: '', timeAgo: '',
      imageUrl: '', unread: false, segment: 'persons',
      threadId, otherUserId: input.userId,
    });
    const saved = await this.repo.save(conv1);
    await this.repo.save(conv2);
    return ok(saved.toObject());
  }
}

// ── Get Messages ──
@Injectable()
export class GetMessagesUseCase implements IUseCase<{ conversationId: string; userId: string }, Result<any[], string>> {
  constructor(
    @Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly convRepo: IConversationRepository,
    @Inject(MESSAGE_REPOSITORY_TOKEN) private readonly msgRepo: IMessageRepository,
  ) {}
  async execute(input: { conversationId: string; userId: string }): Promise<Result<any[], string>> {
    const conv = await this.convRepo.findById(input.conversationId);
    if (!conv) return err('Conversation not found');
    if (!conv.threadId) return ok([]);
    const messages = await this.msgRepo.findByThreadId(conv.threadId);
    return ok(messages.map((m) => m.toObject()));
  }
}

// ── Send Message ──
@Injectable()
export class SendMessageUseCase implements IUseCase<{ conversationId: string; userId: string; text: string; attachmentUrl?: string; attachmentType?: string }, Result<any, string>> {
  constructor(
    @Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly convRepo: IConversationRepository,
    @Inject(MESSAGE_REPOSITORY_TOKEN) private readonly msgRepo: IMessageRepository,
  ) {}
  async execute(input: { conversationId: string; userId: string; text: string; attachmentUrl?: string; attachmentType?: string }): Promise<Result<any, string>> {
    const conv = await this.convRepo.findById(input.conversationId);
    if (!conv) return err('Conversation not found');
    if (!conv.threadId) return err('No thread for this conversation');

    const msg = MessageEntity.create({
      threadId: conv.threadId, senderId: input.userId, text: input.text,
      attachmentUrl: input.attachmentUrl,
      attachmentType: input.attachmentType as AttachmentType | undefined,
    });
    const saved = await this.msgRepo.save(msg);
    conv.updateLastMessage(input.text);
    await this.convRepo.update(conv);
    return ok(saved.toObject());
  }
}

// ── Delete Conversation ──
@Injectable()
export class DeleteConversationUseCase implements IUseCase<{ conversationId: string; userId: string }, Result<void, string>> {
  constructor(@Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly repo: IConversationRepository) {}
  async execute(input: { conversationId: string; userId: string }): Promise<Result<void, string>> {
    const conv = await this.repo.findById(input.conversationId);
    if (!conv) return err('Conversation not found');
    await this.repo.delete(input.conversationId);
    return ok(undefined);
  }
}

// ── Create Group ──
@Injectable()
export class CreateGroupUseCase implements IUseCase<{ userId: string; name: string; imageUrl?: string; participantIds: string[] }, Result<any, string>> {
  constructor(@Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly repo: IConversationRepository) {}
  async execute(input: { userId: string; name: string; imageUrl?: string; participantIds: string[] }): Promise<Result<any, string>> {
    const allParticipants = [input.userId, ...input.participantIds];
    const threadId = Entity.generateId();
    const convs: ConversationEntity[] = [];
    for (const pid of allParticipants) {
      const conv = ConversationEntity.create({
        userId: pid, name: input.name, lastMessage: '', timeAgo: '',
        imageUrl: input.imageUrl ?? '', unread: false, segment: 'persons',
        threadId, participants: allParticipants,
      });
      convs.push(conv);
    }
    const results: any[] = [];
    for (const c of convs) {
      const saved = await this.repo.save(c);
      results.push(saved.toObject());
    }
    return ok(results[0]);
  }
}

// ── Add Member To Group ──
@Injectable()
export class AddMemberToGroupUseCase implements IUseCase<{ conversationId: string; userId: string }, Result<void, string>> {
  constructor(@Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly repo: IConversationRepository) {}
  async execute(input: { conversationId: string; userId: string }): Promise<Result<void, string>> {
    const conv = await this.repo.findById(input.conversationId);
    if (!conv) return err('Conversation not found');
    conv.addParticipant(input.userId);
    await this.repo.update(conv);
    return ok(undefined);
  }
}

// ── Get/Update Settings ──
@Injectable()
export class GetSettingsUseCase implements IUseCase<{ userId: string; conversationId: string }, Result<any, string>> {
  constructor(@Inject(CONVERSATION_SETTING_REPOSITORY_TOKEN) private readonly repo: IConversationSettingRepository) {}
  async execute(input: { userId: string; conversationId: string }): Promise<Result<any, string>> {
    const setting = await this.repo.findByUserAndConversation(input.userId, input.conversationId);
    if (!setting) return ok({ autoSavePhotos: false, muted: false });
    return ok(setting.toObject());
  }
}

@Injectable()
export class UpdateSettingsUseCase implements IUseCase<{ userId: string; conversationId: string; data: { autoSavePhotos?: boolean; muted?: boolean } }, Result<any, string>> {
  constructor(@Inject(CONVERSATION_SETTING_REPOSITORY_TOKEN) private readonly repo: IConversationSettingRepository) {}
  async execute(input: { userId: string; conversationId: string; data: { autoSavePhotos?: boolean; muted?: boolean } }): Promise<Result<any, string>> {
    let setting = await this.repo.findByUserAndConversation(input.userId, input.conversationId);
    if (setting) {
      setting.update(input.data);
      await this.repo.update(setting);
      return ok(setting.toObject());
    }
    setting = ConversationSettingEntity.create({
      userId: input.userId, conversationId: input.conversationId,
      autoSavePhotos: input.data.autoSavePhotos ?? false, muted: input.data.muted ?? false,
    });
    const saved = await this.repo.save(setting);
    return ok(saved.toObject());
  }
}

// ── Get Media ──
@Injectable()
export class GetMediaUseCase implements IUseCase<{ conversationId: string; userId: string }, Result<any[], string>> {
  constructor(
    @Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly convRepo: IConversationRepository,
    @Inject(MESSAGE_REPOSITORY_TOKEN) private readonly msgRepo: IMessageRepository,
  ) {}
  async execute(input: { conversationId: string; userId: string }): Promise<Result<any[], string>> {
    const conv = await this.convRepo.findById(input.conversationId);
    if (!conv?.threadId) return ok([]);
    const media = await this.msgRepo.findMediaByThread(conv.threadId);
    return ok(media.map((m) => m.toObject()));
  }
}

// ── Search Messages ──
@Injectable()
export class SearchMessagesUseCase implements IUseCase<{ conversationId: string; userId: string; query: string }, Result<any[], string>> {
  constructor(
    @Inject(CONVERSATION_REPOSITORY_TOKEN) private readonly convRepo: IConversationRepository,
    @Inject(MESSAGE_REPOSITORY_TOKEN) private readonly msgRepo: IMessageRepository,
  ) {}
  async execute(input: { conversationId: string; userId: string; query: string }): Promise<Result<any[], string>> {
    const conv = await this.convRepo.findById(input.conversationId);
    if (!conv?.threadId) return ok([]);
    const msgs = await this.msgRepo.searchByText(conv.threadId, input.query);
    return ok(msgs.map((m) => m.toObject()));
  }
}

// ── Upload Attachment ──
@Injectable()
export class UploadAttachmentUseCase implements IUseCase<{ buffer: Buffer; mimetype: string }, Result<string, string>> {
  async execute(input: { buffer: Buffer; mimetype: string }): Promise<Result<string, string>> {
    try {
      const path = await import('path');
      const fs = await import('fs/promises');
      const crypto = await import('crypto');
      const dir = path.join(process.cwd(), 'uploads', 'attachments');
      await fs.mkdir(dir, { recursive: true });
      const ext = input.mimetype.includes('png') ? 'png' : input.mimetype.includes('webp') ? 'webp' : input.mimetype.includes('audio') ? 'webm' : 'jpg';
      const filename = `${crypto.randomUUID()}.${ext}`;
      await fs.writeFile(path.join(dir, filename), input.buffer);
      return ok(`/uploads/attachments/${filename}`);
    } catch (error) {
      return err(error instanceof Error ? error.message : 'Upload failed');
    }
  }
}
