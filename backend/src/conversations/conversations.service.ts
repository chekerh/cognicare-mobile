import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';
import {
  Conversation,
  ConversationDocument,
  ConversationSegment,
} from './conversation.schema';
import { Message, MessageDocument } from './message.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import * as crypto from 'crypto';

@Injectable()
export class ConversationsService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name)
    private readonly messageModel: Model<MessageDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    private readonly configService: ConfigService,
  ) {}

  /** Derive a 32-byte AES key from env (MESSAGES_ENCRYPTION_KEY) or a fallback string. */
  private getEncryptionKey(): Buffer {
    const secret =
      this.configService.get<string>('MESSAGES_ENCRYPTION_KEY') ||
      'cognicare-dev-fallback-message-key';
    return crypto.createHash('sha256').update(secret).digest();
  }

  /** Encrypt plaintext using AES-256-GCM. Returns base64(iv + tag + ciphertext). */
  private encryptMessage(plaintext: string): string {
    const key = this.getEncryptionKey();
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]).toString('base64');
  }

  /**
   * Decrypt message text.
   * For backward compatibility, if decryption fails, returns the original text.
   */
  private decryptMessage(possiblyEncrypted: string): string {
    if (!possiblyEncrypted) return '';
    try {
      const key = this.getEncryptionKey();
      const buf = Buffer.from(possiblyEncrypted, 'base64');
      if (buf.length < 16 + 12) {
        // Too short to contain iv + tag + ciphertext -> assume plaintext
        return possiblyEncrypted;
      }
      const iv = buf.subarray(0, 12);
      const tag = buf.subarray(12, 28);
      const ciphertext = buf.subarray(28);
      const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
      decipher.setAuthTag(tag);
      const decrypted = Buffer.concat([
        decipher.update(ciphertext),
        decipher.final(),
      ]);
      return decrypted.toString('utf8');
    } catch {
      // Old messages stored in plaintext or invalid data: just return as-is
      return possiblyEncrypted;
    }
  }

  async findInboxForUser(userId: string) {
    const docs = await this.conversationModel
      .find({ user: userId })
      .sort({ updatedAt: -1 })
      .lean()
      .exec();

    type Doc = {
      otherUserId?: { toString(): string };
      _id: { toString(): string };
      name?: string;
      segment?: string;
      subtitle?: string;
      lastMessage?: string;
      timeAgo?: string;
      imageUrl?: string;
      unread?: boolean;
    };
    type UserLean = {
      _id?: { toString(): string };
      role?: string;
      fullName?: string;
      profilePic?: string;
    };

    const otherIdStrs = [
      ...new Set(
        (docs as Doc[])
          .map((c) => c.otherUserId?.toString())
          .filter((s): s is string => Boolean(s)),
      ),
    ];
    const otherIds = otherIdStrs.map((id) => new Types.ObjectId(id));
    const users = otherIds.length
      ? await this.userModel
          .find({ _id: { $in: otherIds } })
          .select('role fullName profilePic')
          .lean()
          .exec()
      : [];
    const roleById = new Map<string, string>();
    const nameById = new Map<string, string>();
    const profilePicById = new Map<string, string>();
    for (const u of users as UserLean[]) {
      const id = u._id?.toString();
      if (id) {
        roleById.set(id, String(u.role ?? '').toLowerCase());
        if (u.fullName != null) nameById.set(id, u.fullName);
        if (u.profilePic != null) profilePicById.set(id, u.profilePic);
      }
    }

    return (docs as Doc[]).map((c) => {
      const otherId = c.otherUserId?.toString();
      const otherRole = otherId ? (roleById.get(otherId) ?? null) : null;
      const segment: ConversationSegment =
        otherRole === 'volunteer'
          ? 'benevole'
          : otherRole === 'family'
            ? 'families'
            : ((c.segment as ConversationSegment) ?? 'persons');
      const displayName = otherId
        ? (nameById.get(otherId) ?? c.name ?? '')
        : (c.name ?? '');
      const displayImageUrl = otherId
        ? (profilePicById.get(otherId) ?? c.imageUrl ?? '')
        : (c.imageUrl ?? '');
      return {
        id: c._id.toString(),
        name: displayName,
        subtitle: c.subtitle,
        lastMessage: c.lastMessage
          ? this.decryptMessage(c.lastMessage)
          : undefined,
        timeAgo: c.timeAgo,
        imageUrl: displayImageUrl,
        unread: c.unread,
        segment,
      };
    });
  }

  /** Get or create a conversation between current user and otherUserId. Returns conversation for current user. */
  async getOrCreateConversation(
    userId: string,
    otherUserId: string,
    options?: {
      name?: string;
      imageUrl?: string;
      segment?: ConversationSegment;
      otherSegment?: ConversationSegment;
    },
  ) {
    const uid = new Types.ObjectId(userId);
    const oid = new Types.ObjectId(otherUserId);
    const conv = await this.conversationModel
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
    const otherUser = await this.userModel
      .findById(oid)
      .select('role fullName')
      .lean()
      .exec();
    const otherUserLean = otherUser as {
      role?: string;
      fullName?: string;
    } | null;
    const otherRole = otherUserLean?.role?.toLowerCase?.();
    const segmentForCurrentUser: ConversationSegment =
      otherRole === 'volunteer'
        ? 'benevole'
        : otherRole === 'family'
          ? 'families'
          : 'persons';
    const [created] = await this.conversationModel.create([
      {
        user: uid,
        otherUserId: oid,
        threadId,
        name: options?.name ?? otherUserLean?.fullName ?? 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: options?.imageUrl ?? '',
        segment: options?.segment ?? segmentForCurrentUser,
      },
      {
        user: oid,
        otherUserId: uid,
        threadId,
        name: options?.name ?? 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: options?.imageUrl ?? '',
        segment: options?.otherSegment ?? options?.segment ?? 'persons',
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
      text: this.decryptMessage(m.text),
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
    const encryptedText = this.encryptMessage(text);
    const created = await this.messageModel.create({
      threadId,
      senderId: uid,
      text: encryptedText,
    });
    const timeAgo = formatTimeAgo(new Date());
    await this.conversationModel
      .updateMany(
        { $or: [{ _id: conv._id }, { threadId }] },
        { lastMessage: encryptedText, timeAgo, updatedAt: new Date() },
      )
      .exec();
    return {
      id: created._id.toString(),
      senderId: created.senderId.toString(),
      text,
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
