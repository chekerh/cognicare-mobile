import { Types } from 'mongoose';
import { PostEntity } from '../../domain/entities/post.entity';
import { PostDocument } from '../persistence/mongo/post.schema';

export class PostMapper {
  static toDomain(doc: PostDocument): PostEntity {
    return PostEntity.reconstitute(doc._id.toString(), {
      authorId: doc.authorId.toString(),
      authorName: doc.authorName,
      text: doc.text,
      imageUrl: doc.imageUrl,
      tags: doc.tags ?? [],
      likedBy: (doc.likedBy ?? []).map((id) => id.toString()),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: PostEntity): Record<string, unknown> {
    return {
      authorId: new Types.ObjectId(entity.authorId),
      authorName: entity.authorName,
      text: entity.text,
      imageUrl: entity.imageUrl,
      tags: entity.tags,
      likedBy: entity.likedBy.map((id) => new Types.ObjectId(id)),
    };
  }
}
