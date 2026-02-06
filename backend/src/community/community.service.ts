import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Post, PostDocument } from './schemas/post.schema';
import { Comment, CommentDocument } from './schemas/comment.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

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
  constructor(
    @InjectModel(Post.name) private postModel: Model<PostDocument>,
    @InjectModel(Comment.name) private commentModel: Model<CommentDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async uploadPostImage(file: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<string> {
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
    const user = await this.userModel
      .findById(userId)
      .select('fullName')
      .exec();
    if (!user) throw new NotFoundException('User not found');

    const post = new this.postModel({
      authorId: new Types.ObjectId(userId),
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
      text: string;
      createdAt: string;
      hasImage: boolean;
      imagePath: string | null;
      imageUrl?: string;
      tags: string[];
      likeCount: number;
    }[]
  > {
    const posts = await this.postModel
      .find()
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    return (posts as PostLean[]).map((p) => ({
      id: p._id.toString(),
      authorId: p.authorId.toString(),
      authorName: p.authorName,
      text: p.text,
      createdAt: p.createdAt.toISOString(),
      hasImage: !!p.imageUrl,
      imagePath: p.imageUrl ?? null,
      imageUrl: p.imageUrl,
      tags: p.tags ?? [],
      likeCount: (p.likedBy ?? []).length,
    }));
  }

  async updatePost(
    postId: string,
    userId: string,
    dto: UpdatePostDto,
  ): Promise<void> {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId.toString() !== userId) {
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
    if (post.authorId.toString() !== userId) {
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
}
