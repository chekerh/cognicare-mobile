import { CommentEntity } from '../entities/comment.entity';

export const COMMENT_REPOSITORY_TOKEN = Symbol('ICommentRepository');

export interface ICommentRepository {
  findByPostId(postId: string): Promise<CommentEntity[]>;
  save(entity: CommentEntity): Promise<CommentEntity>;
  deleteByPostId(postId: string): Promise<void>;
}
