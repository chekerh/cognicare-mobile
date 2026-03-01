import { Types } from 'mongoose';
import { CommentEntity } from '../../domain/entities/comment.entity';
import { CommentDocument } from '../persistence/mongo/comment.schema';

export class CommentMapper {
  static toDomain(doc: CommentDocument): CommentEntity {
    return CommentEntity.reconstitute(doc._id.toString(), {
      postId: doc.postId.toString(),
      authorId: doc.authorId.toString(),
      authorName: doc.authorName,
      text: doc.text,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: CommentEntity): Record<string, unknown> {
    return {
      postId: new Types.ObjectId(entity.postId),
      authorId: new Types.ObjectId(entity.authorId),
      authorName: entity.authorName,
      text: entity.text,
    };
  }
}
