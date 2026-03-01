import { PostEntity } from '../entities/post.entity';

export const POST_REPOSITORY_TOKEN = Symbol('IPostRepository');

export interface IPostRepository {
  findById(id: string): Promise<PostEntity | null>;
  findAll(): Promise<PostEntity[]>;
  findByAuthorId(authorId: string): Promise<PostEntity[]>;
  save(entity: PostEntity): Promise<PostEntity>;
  update(entity: PostEntity): Promise<void>;
  delete(id: string): Promise<void>;
  findByIds(ids: string[]): Promise<PostEntity[]>;
}
