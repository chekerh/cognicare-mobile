import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as crypto from 'crypto';
import {
  Conversation,
  ConversationDocument,
  ConversationSegment,
} from './conversation.schema';
import { Message, MessageDocument } from './message.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

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
    const uid = new Types.ObjectId(userId);
    const docs = await this.conversationModel
      .find({
        $or: [{ user: uid }, { otherUserId: uid }],
      })
      .sort({ updatedAt: -1 })
      .lean()
      .exec();

    type Doc = {
      user?: { toString(): string };
      otherUserId?: { toString(): string };
      threadId?: { toString(): string };
      _id: { toString(): string };
      name?: string;
      segment?: string;
      subtitle?: string;
      lastMessage?: string;
      timeAgo?: string;
      imageUrl?: string;
      unread?: boolean;
    };
    // One row per thread: prefer doc where user = current user (so id is theirs)
    const byThread = new Map<string, Doc>();
    for (const c of docs as Doc[]) {
      const tid = (c.threadId ?? c._id)?.toString() ?? c._id.toString();
      const existing = byThread.get(tid);
      const isMine = c.user?.toString() === userId;
      if (!existing || (isMine && existing.user?.toString() !== userId))
        byThread.set(tid, c);
    }
    const uniqueDocs = Array.from(byThread.values());
    type UserLean = {
      _id?: { toString(): string };
      role?: string;
      fullName?: string;
      profilePic?: string;
    };

    const otherIdStrs = [
      ...new Set(
        uniqueDocs
          .map((c) => {
            const userStr = c.user?.toString();
            const otherStr = c.otherUserId?.toString();
            if (otherStr === userId && userStr) return userStr;
            return otherStr;
          })
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

    return uniqueDocs.map((c) => {
      const userStr = c.user?.toString();
      const otherUserIdStr = c.otherUserId?.toString();
      const isCurrentInUser = userStr === userId;
      const otherId = isCurrentInUser ? otherUserIdStr : userStr;
      const otherRole = otherId ? (roleById.get(otherId) ?? null) : null;
      const segment: ConversationSegment =
        otherRole === 'volunteer'
          ? 'benevole'
          : otherRole === 'family'
            ? 'families'
            : otherRole === 'healthcare'
              ? 'healthcare'
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
    currentUserRole?: string,
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
    const role = currentUserRole?.toLowerCase?.();

    // Segment for the user making the request (current user)
    const segmentForCurrentUser: ConversationSegment =
      otherRole === 'volunteer'
        ? 'benevole' // current user talks to a volunteer
        : otherRole === 'family'
          ? 'families' // current user talks to a family
          : otherRole === 'healthcare'
            ? 'healthcare' // current user talks to healthcare
            : 'persons';

    // Segment for the other side (so that conversations appear correctly in their inbox)
    const segmentForOtherUser: ConversationSegment =
      role === 'volunteer' && otherRole === 'family'
        ? 'benevole' // family sees volunteer under "Benevole"
        : role === 'family' && otherRole === 'volunteer'
          ? 'families' // volunteer sees family under "Familles"
          : role === 'volunteer'
            ? 'benevole'
            : role === 'family'
              ? 'families'
              : role === 'healthcare'
                ? 'healthcare' // other user sees healthcare under "Healthcare"
                : 'persons';
    const [created] = await this.conversationModel.create([
      {
        user: uid,
        otherUserId: oid,
        threadId,
        name: otherUserLean?.fullName ?? 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: '',
        segment: segmentForCurrentUser,
      },
      {
        user: oid,
        otherUserId: uid,
        threadId,
        name: 'Conversation',
        lastMessage: '',
        timeAgo: '',
        imageUrl: '',
        segment: segmentForOtherUser,
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
      attachmentUrl: (m as any).attachmentUrl,
      attachmentType: (m as any).attachmentType,
    }));
  }

  /** Upload chat attachment (image or voice). Returns public URL path. */
  async uploadAttachment(
    userId: string,
    file: { buffer: Buffer; mimetype: string },
    type: 'image' | 'voice',
  ): Promise<string> {
    const m = (file.mimetype ?? '').toLowerCase();
    if (type === 'image') {
      // Accept image/* or empty/octet-stream (Flutter image_picker may not send mimetype)
      const isImage = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
      ].some((a) => m === a || m.startsWith(a + ';'));
      const isUnknown = !m || m === 'application/octet-stream';
      if (!isImage && !isUnknown) {
        throw new BadRequestException(
          'Invalid image type. Use JPEG, PNG or WebP.',
        );
      }
    } else {
      // Voice: accept audio/* or empty/octet-stream (Flutter record sends .m4a often without mimetype)
      const isAudio = m.startsWith('audio/');
      const isUnknown = !m || m === 'application/octet-stream';
      if (!isAudio && !isUnknown) {
        throw new BadRequestException(
          'Invalid audio type. Use MP3, M4A or AAC.',
        );
      }
    }
    const ext =
      type === 'voice'
        ? 'm4a'
        : m.includes('png')
          ? 'png'
          : m.includes('webp')
            ? 'webp'
            : m.includes('heic')
              ? 'heic'
              : 'jpg';
    const dir = path.join(process.cwd(), 'uploads', 'chat');
    await fs.mkdir(dir, { recursive: true });
    const name = `${type}-${userId}-${crypto.randomUUID()}.${ext}`;
    const filePath = path.join(dir, name);
    await fs.writeFile(filePath, file.buffer);
    return `/uploads/chat/${name}`;
  }

  async addMessage(
    conversationId: string,
    userId: string,
    text: string,
    attachmentUrl?: string,
    attachmentType?: 'image' | 'voice',
  ) {
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
      ...(attachmentUrl && { attachmentUrl }),
      ...(attachmentType && { attachmentType }),
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

  async deleteConversation(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    const conv = await this.conversationModel.findById(conversationId).exec();
    if (!conv) throw new NotFoundException('Conversation not found');
    const uid = new Types.ObjectId(userId);
    if (!conv.user.equals(uid) && !conv.otherUserId?.equals(uid)) {
      throw new ForbiddenException('Not a participant');
    }
    const threadId = conv.threadId ?? conv._id;
    // Delete all conversation rows for this thread (both sides) so it disappears for everyone.
    await this.conversationModel.deleteMany({ threadId }).exec();
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
