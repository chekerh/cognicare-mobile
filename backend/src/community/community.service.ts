import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Post, PostDocument } from './schemas/post.schema';
import { Comment, CommentDocument } from './schemas/comment.schema';
import {
  FollowRequest,
  FollowRequestDocument,
  FollowRequestStatus,
} from './schemas/follow-request.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { NotificationsService } from '../notifications/notifications.service';

interface PostLean {
  _id: Types.ObjectId;
  authorId: Types.ObjectId;
  authorName: string;
  text: string;
  createdAt: Date;
  imageUrl?: string;
  tags: string[];
  likedBy: Types.ObjectId[];
}

interface CommentLean {
  _id: Types.ObjectId;
  authorName: string;
  text: string;
  createdAt: Date;
}

@Injectable()
export class CommunityService {
  private readonly logger = new Logger(CommunityService.name);

  constructor(
    @InjectModel(Post.name) private postModel: Model<PostDocument>,
    @InjectModel(Comment.name) private commentModel: Model<CommentDocument>,
    @InjectModel(FollowRequest.name)
    private followRequestModel: Model<FollowRequestDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private cloudinary: CloudinaryService,
    private notifications: NotificationsService,
  ) {}

  async uploadPostImage(file: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<string> {
    if (this.cloudinary.isConfigured()) {
      const crypto = await import('crypto');
      const publicId = `post-${crypto.randomUUID()}`;
      return this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/posts',
        publicId,
      });
    }
    const path = await import('path');
    const fs = await import('fs/promises');
    const crypto = await import('crypto');
    const uploadsDir = path.join(process.cwd(), 'uploads', 'posts');
    await fs.mkdir(uploadsDir, { recursive: true });
    const m = file.mimetype ?? '';
    const ext =
      m === 'image/png'
        ? 'png'
        : m === 'image/webp'
          ? 'webp'
          : m === 'image/heic'
            ? 'heic'
            : 'jpg';
    const id = crypto.randomUUID();
    const filename = `${id}.${ext}`;
    const filePath = path.join(uploadsDir, filename);
    await fs.writeFile(filePath, file.buffer);
    return `/uploads/posts/${filename}`;
  }

  async createPost(
    userId: string,
    dto: CreatePostDto,
  ): Promise<{
    id: string;
    authorName: string;
    authorId: string;
    text: string;
    createdAt: string;
    imageUrl?: string;
    tags: string[];
    likeCount: number;
  }> {
    const uid = this.normalizeUserId(userId);
    const user = await this.userModel.findById(uid).select('fullName').exec();
    if (!user) throw new NotFoundException('User not found');

    const post = new this.postModel({
      authorId: new Types.ObjectId(uid),
      authorName: user.fullName,
      text: dto.text,
      imageUrl: dto.imageUrl,
      tags: dto.tags ?? [],
      likedBy: [],
    });
    await post.save();

    return {
      id: post._id.toString(),
      authorId: post.authorId.toString(),
      authorName: post.authorName,
      text: post.text,
      createdAt: post.createdAt!.toISOString(),
      imageUrl: post.imageUrl,
      tags: post.tags,
      likeCount: 0,
    };
  }

  async getPosts(): Promise<
    {
      id: string;
      authorName: string;
      authorId: string;
      authorProfilePic?: string | null;
      text: string;
      createdAt: string;
      hasImage: boolean;
      imagePath: string | null;
      imageUrl?: string;
      tags: string[];
      likeCount: number;
      commentCount: number;
    }[]
  > {
    const posts = await this.postModel
      .find()
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    const postIds = (posts as PostLean[]).map((p) => p._id);
    const authorIds = [
      ...new Set(
        (posts as PostLean[]).map((p) => p.authorId.toString()),
      ),
    ];
    const users = await this.userModel
      .find({ _id: { $in: authorIds.map((id) => new Types.ObjectId(id)) } })
      .select('profilePic')
      .lean()
      .exec();
    const profilePicByAuthorId = new Map<string, string>();
    for (const u of users as { _id: Types.ObjectId; profilePic?: string }[]) {
      const id = u._id.toString();
      if (u.profilePic) profilePicByAuthorId.set(id, u.profilePic);
    }

    const commentCounts = await this.commentModel
      .aggregate<{ _id: Types.ObjectId; count: number }>([
        { $match: { postId: { $in: postIds } } },
        { $group: { _id: '$postId', count: { $sum: 1 } } },
      ])
      .exec();
    const countByPostId = new Map<string, number>();
    for (const row of commentCounts) {
      countByPostId.set(row._id.toString(), row.count);
    }

    return (posts as PostLean[]).map((p) => ({
      id: p._id.toString(),
      authorId: p.authorId.toString(),
      authorName: p.authorName,
      authorProfilePic: profilePicByAuthorId.get(p.authorId.toString()) ?? null,
      text: p.text,
      createdAt: p.createdAt.toISOString(),
      hasImage: !!p.imageUrl,
      imagePath: p.imageUrl ?? null,
      imageUrl: p.imageUrl,
      tags: p.tags ?? [],
      likeCount: (p.likedBy ?? []).length,
      commentCount: countByPostId.get(p._id.toString()) ?? 0,
    }));
  }

  /** Get posts by a specific author (for profile feed). Same shape as getPosts(). */
  async getPostsByAuthor(authorId: string): Promise<
    {
      id: string;
      authorName: string;
      authorId: string;
      authorProfilePic?: string | null;
      text: string;
      createdAt: string;
      hasImage: boolean;
      imagePath: string | null;
      imageUrl?: string;
      tags: string[];
      likeCount: number;
      commentCount: number;
    }[]
  > {
    const oid = new Types.ObjectId(authorId);
    const posts = await this.postModel
      .find({ authorId: oid })
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    const postIds = (posts as PostLean[]).map((p) => p._id);
    const users = await this.userModel
      .find({ _id: oid })
      .select('profilePic')
      .lean()
      .exec();
    const profilePic =
      (users as { _id: Types.ObjectId; profilePic?: string }[])[0]?.profilePic ??
      null;

    const commentCounts = await this.commentModel
      .aggregate<{ _id: Types.ObjectId; count: number }>([
        { $match: { postId: { $in: postIds } } },
        { $group: { _id: '$postId', count: { $sum: 1 } } },
      ])
      .exec();
    const countByPostId = new Map<string, number>();
    for (const row of commentCounts) {
      countByPostId.set(row._id.toString(), row.count);
    }

    return (posts as PostLean[]).map((p) => ({
      id: p._id.toString(),
      authorId: p.authorId.toString(),
      authorName: p.authorName,
      authorProfilePic: profilePic,
      text: p.text,
      createdAt: p.createdAt.toISOString(),
      hasImage: !!p.imageUrl,
      imagePath: p.imageUrl ?? null,
      imageUrl: p.imageUrl,
      tags: p.tags ?? [],
      likeCount: (p.likedBy ?? []).length,
      commentCount: countByPostId.get(p._id.toString()) ?? 0,
    }));
  }

  private normalizeUserId(userId: string | { toString(): string }): string {
    const s = typeof userId === 'string' ? userId : userId.toString();
    return (s ?? '').trim();
  }

  private isSameUser(userId: string, authorId: Types.ObjectId): boolean {
    const uid = this.normalizeUserId(userId);
    if (!uid) return false;
    if (Types.ObjectId.isValid(uid) && String(authorId).length === 24) {
      return new Types.ObjectId(uid).equals(authorId);
    }
    return (authorId?.toString() ?? '').trim() === uid;
  }

  async updatePost(
    postId: string,
    userId: string,
    dto: UpdatePostDto,
  ): Promise<void> {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post not found');
    if (!this.isSameUser(userId, post.authorId)) {
      throw new ForbiddenException('You can only edit your own posts');
    }
    if (dto.text !== undefined) post.text = dto.text;
    if (dto.imageUrl !== undefined) post.imageUrl = dto.imageUrl;
    if (dto.tags !== undefined) post.tags = dto.tags;
    await post.save();
  }

  async deletePost(postId: string, userId: string): Promise<void> {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post not found');
    if (!this.isSameUser(userId, post.authorId)) {
      this.logger.warn(
        `Delete denied: uid=${this.normalizeUserId(userId)} authorId=${post.authorId?.toString()} postId=${postId}`,
      );
      throw new ForbiddenException('You can only delete your own posts');
    }
    await this.commentModel
      .deleteMany({ postId: new Types.ObjectId(postId) })
      .exec();
    await this.postModel.findByIdAndDelete(postId).exec();
  }

  async toggleLike(
    postId: string,
    userId: string,
  ): Promise<{ liked: boolean; likeCount: number }> {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post not found');

    const uid = new Types.ObjectId(userId);
    const likedBy = post.likedBy ?? [];
    const index = likedBy.findIndex((id) => id.equals(uid));
    if (index >= 0) {
      likedBy.splice(index, 1);
      post.likedBy = likedBy;
    } else {
      post.likedBy = [...likedBy, uid];
    }
    await post.save();

    return {
      liked: post.likedBy.some((id) => id.equals(uid)),
      likeCount: post.likedBy.length,
    };
  }

  async getComments(
    postId: string,
  ): Promise<{ authorName: string; text: string; createdAt: string }[]> {
    const comments = await this.commentModel
      .find({ postId: new Types.ObjectId(postId) })
      .sort({ createdAt: 1 })
      .lean()
      .exec();

    return (comments as CommentLean[]).map((c) => ({
      authorName: c.authorName,
      text: c.text,
      createdAt: c.createdAt.toISOString(),
    }));
  }

  async addComment(
    postId: string,
    userId: string,
    dto: CreateCommentDto,
  ): Promise<{ authorName: string; text: string; createdAt: string }> {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post not found');

    const user = await this.userModel
      .findById(userId)
      .select('fullName')
      .exec();
    if (!user) throw new NotFoundException('User not found');

    const comment = new this.commentModel({
      postId: new Types.ObjectId(postId),
      authorId: new Types.ObjectId(userId),
      authorName: user.fullName,
      text: dto.text.trim(),
    });
    await comment.save();

    return {
      authorName: comment.authorName,
      text: comment.text,
      createdAt: comment.createdAt!.toISOString(),
    };
  }

  async getPostLikeStatus(
    postIds: string[],
    userId: string,
  ): Promise<Record<string, boolean>> {
    if (postIds.length === 0) return {};
    const uid = new Types.ObjectId(userId);
    const posts = await this.postModel
      .find({ _id: { $in: postIds.map((id) => new Types.ObjectId(id)) } })
      .select('_id likedBy')
      .lean()
      .exec();

    const result: Record<string, boolean> = {};
    for (const p of posts as PostLean[]) {
      const id = p._id.toString();
      const likedBy = p.likedBy ?? [];
      result[id] = likedBy.some((oid) => oid.equals(uid));
    }
    return result;
  }

  // --- Follow requests ---

  async createFollowRequest(
    requesterId: string,
    targetUserId: string,
  ): Promise<{ requestId: string; status: FollowRequestStatus }> {
    const requesterOid = new Types.ObjectId(requesterId);
    const targetOid = new Types.ObjectId(targetUserId);
    if (requesterOid.equals(targetOid)) {
      throw new BadRequestException('Cannot follow yourself');
    }
    const target = await this.userModel.findById(targetOid).exec();
    if (!target) throw new NotFoundException('User not found');

    const requester = await this.userModel
      .findById(requesterOid)
      .select('fullName profilePic')
      .lean()
      .exec();
    const requesterName =
      (requester as { fullName?: string } | null)?.fullName ?? 'Un membre';
    const requesterProfilePic =
      (requester as { profilePic?: string } | null)?.profilePic ?? undefined;

    let doc = await this.followRequestModel
      .findOne({ requesterId: requesterOid, targetId: targetOid })
      .exec();
    if (doc) {
      if (doc.status === 'accepted') {
        return { requestId: doc._id.toString(), status: 'accepted' };
      }
      if (doc.status === 'pending') {
        return { requestId: doc._id.toString(), status: 'pending' };
      }
      doc.status = 'pending';
      doc.updatedAt = new Date();
      await doc.save();
    } else {
      doc = await this.followRequestModel.create({
        requesterId: requesterOid,
        targetId: targetOid,
        status: 'pending',
      });
    }

    await this.notifications.createForUser(targetUserId, {
      type: 'follow_request',
      title: 'Demande de suivi',
      description: `${requesterName} souhaite vous suivre. Acceptez pour pouvoir le contacter (appel, message).`,
      data: {
        requestId: doc._id.toString(),
        requesterId: requesterId,
        requesterName,
        requesterProfilePic: requesterProfilePic ?? null,
      },
    });

    return { requestId: doc._id.toString(), status: 'pending' };
  }

  /** Liste des amis (personnes avec relation acceptée : je les suis ou ils me suivent). */
  async listFriends(
    userId: string,
  ): Promise<{ id: string; fullName: string; profilePic?: string }[]> {
    const list = await this.followRequestModel
      .find({ status: 'accepted' })
      .or([
        { targetId: new Types.ObjectId(userId) },
        { requesterId: new Types.ObjectId(userId) },
      ])
      .lean()
      .exec();
    const otherIds = new Set<string>();
    for (const r of list as { requesterId: Types.ObjectId; targetId: Types.ObjectId }[]) {
      const req = r.requesterId.toString();
      const tgt = r.targetId.toString();
      if (req === userId) otherIds.add(tgt);
      else otherIds.add(req);
    }
    if (otherIds.size === 0) return [];
    const users = await this.userModel
      .find({ _id: { $in: [...otherIds].map((id) => new Types.ObjectId(id)) } })
      .select('_id fullName profilePic')
      .lean()
      .exec();
    return (users as { _id: Types.ObjectId; fullName?: string; profilePic?: string }[]).map(
      (u) => ({
        id: u._id.toString(),
        fullName: u.fullName ?? 'Membre',
        profilePic: u.profilePic,
      }),
    );
  }

  /** Infos publiques d'un membre (nom, photo, email, phone, location) pour afficher le profil. */
  async getMemberPublicInfo(
    userId: string,
  ): Promise<{ fullName: string; profilePic?: string; email?: string; phone?: string; location?: string } | null> {
    const user = await this.userModel
      .findById(userId)
      .select('fullName profilePic email phone location')
      .lean()
      .exec();
    if (!user) return null;
    const u = user as { fullName?: string; profilePic?: string; email?: string; phone?: string; location?: string };
    return {
      fullName: u.fullName ?? 'Membre',
      profilePic: u.profilePic,
      email: u.email,
      phone: u.phone,
      location: u.location,
    };
  }

  /** Infos de contact d'un membre (email, phone, location) — uniquement si amis. */
  async getMemberContactInfo(
    currentUserId: string,
    targetUserId: string,
  ): Promise<{ fullName: string; email?: string; phone?: string; location?: string } | null> {
    const status = await this.getFollowStatus(currentUserId, targetUserId);
    if (status.status !== 'accepted') return null;
    const user = await this.userModel
      .findById(targetUserId)
      .select('fullName email phone location')
      .lean()
      .exec();
    if (!user) return null;
    const u = user as { fullName?: string; email?: string; phone?: string; location?: string };
    return {
      fullName: u.fullName ?? 'Membre',
      email: u.email,
      phone: u.phone,
      location: u.location,
    };
  }

  /** Statut de la relation entre currentUserId et targetUserId (dans les deux sens). */
  async getFollowStatus(
    currentUserId: string,
    targetUserId: string,
  ): Promise<{ status: FollowRequestStatus | null; requestId?: string | null }> {
    const me = new Types.ObjectId(currentUserId);
    const them = new Types.ObjectId(targetUserId);
    const doc = await this.followRequestModel
      .findOne({
        $or: [
          { requesterId: me, targetId: them },
          { requesterId: them, targetId: me },
        ],
      })
      .lean()
      .exec();
    const d = doc as { _id: Types.ObjectId; status: string; requesterId: Types.ObjectId } | null;
    if (!d) return { status: null, requestId: null };
    const status = d.status as FollowRequestStatus;
    const requestId =
      d.requesterId.equals(me) ? d._id.toString() : null;
    return { status, requestId };
  }

  async listPendingFollowRequests(
    userId: string,
  ): Promise<
    { id: string; requesterId: string; requesterName: string; requesterProfilePic?: string; createdAt: string }[]
  > {
    const list = await this.followRequestModel
      .find({ targetId: new Types.ObjectId(userId), status: 'pending' })
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    const requesterIds = [
      ...new Set(
        (list as { requesterId: Types.ObjectId }[]).map((r) =>
          r.requesterId.toString(),
        ),
      ),
    ];
    const users = await this.userModel
      .find({ _id: { $in: requesterIds.map((id) => new Types.ObjectId(id)) } })
      .select('fullName profilePic')
      .lean()
      .exec();
    const nameById: Record<string, string> = {};
    const picById: Record<string, string | undefined> = {};
    for (const u of users as { _id: Types.ObjectId; fullName?: string; profilePic?: string }[]) {
      const id = u._id.toString();
      nameById[id] = u.fullName ?? 'Membre';
      picById[id] = u.profilePic;
    }

    return (list as { _id: Types.ObjectId; requesterId: Types.ObjectId; createdAt: Date }[]).map(
      (r) => ({
        id: r._id.toString(),
        requesterId: r.requesterId.toString(),
        requesterName: nameById[r.requesterId.toString()] ?? 'Membre',
        requesterProfilePic: picById[r.requesterId.toString()],
        createdAt: r.createdAt.toISOString(),
      }),
    );
  }

  async acceptFollowRequest(
    requestId: string,
    userId: string,
  ): Promise<void> {
    const doc = await this.followRequestModel.findById(requestId).exec();
    if (!doc) throw new NotFoundException('Follow request not found');
    if (!doc.targetId.equals(new Types.ObjectId(userId))) {
      throw new ForbiddenException('Only the target user can accept');
    }
    if (doc.status !== 'pending') {
      if (doc.status === 'accepted') {
        try {
          await this.notifications.deleteByFollowRequestId(userId, requestId);
        } catch (e) {
          this.logger.warn('deleteByFollowRequestId failed on accept (idempotent)', e);
        }
        return;
      }
      throw new BadRequestException('Request is no longer pending');
    }
    doc.status = 'accepted';
    doc.updatedAt = new Date();
    await doc.save();
    try {
      await this.notifications.deleteByFollowRequestId(userId, requestId);
    } catch (e) {
      this.logger.warn('deleteByFollowRequestId failed on accept', e);
    }
  }

  /** Annuler sa propre demande de suivi (le demandeur retire sa demande). Idempotent : si la demande n'existe plus (déjà refusée/supprimée), on ne lance pas d'erreur. */
  async cancelFollowRequest(
    requestId: string,
    userId: string,
  ): Promise<void> {
    if (!requestId || !Types.ObjectId.isValid(requestId)) return;
    const doc = await this.followRequestModel.findById(requestId).exec();
    if (!doc) return; // Déjà supprimée (ex. refusée par la cible) → succès pour l'UI
    const requesterIdStr = doc.requesterId.toString();
    if (requesterIdStr !== userId) {
      throw new ForbiddenException('Only the requester can cancel their request');
    }
    if (doc.status !== 'pending') return;
    const targetId = doc.targetId.toString();
    try {
      await this.notifications.deleteByFollowRequestId(targetId, requestId);
    } catch (e) {
      this.logger.warn('deleteByFollowRequestId failed on cancel', e);
    }
    await this.followRequestModel.deleteOne({ _id: doc._id }).exec();
  }

  /** Refuser une demande de suivi : suppression totale (demande + notification). Le demandeur (ex. Malek) pourra renvoyer une demande. */
  async declineFollowRequest(
    requestId: string,
    userId: string,
  ): Promise<void> {
    const doc = await this.followRequestModel.findById(requestId).exec();
    if (doc && !doc.targetId.equals(new Types.ObjectId(userId))) {
      throw new ForbiddenException('Only the target user can decline');
    }
    // Supprimer la notif pour qu'elle disparaisse au rechargement.
    await this.notifications.deleteByFollowRequestId(userId, requestId);
    // Toujours supprimer le document demande pour que le demandeur (Malek) puisse recliquer « Suivre ».
    if (doc) {
      await this.followRequestModel.deleteOne({ _id: doc._id }).exec();
    }
  }
}
