/**
 * Refresh Token Mapper - Infrastructure Layer
 */
import { Types } from 'mongoose';
import { RefreshTokenEntity } from '../../domain/entities/refresh-token.entity';
import { RefreshTokenDocument } from '../persistence/mongo/refresh-token.schema';

export class RefreshTokenMapper {
  static toDomain(doc: RefreshTokenDocument): RefreshTokenEntity {
    return RefreshTokenEntity.reconstitute(doc._id.toString(), {
      userId: doc.userId.toString(),
      tokenHash: doc.tokenHash,
      expiresAt: doc.expiresAt,
      deviceInfo: doc.deviceInfo,
      createdAt: doc.createdAt,
    });
  }

  static toPersistence(entity: RefreshTokenEntity): Record<string, unknown> {
    return {
      userId: new Types.ObjectId(entity.userId),
      tokenHash: entity.tokenHash,
      expiresAt: entity.expiresAt,
      deviceInfo: entity.deviceInfo,
    };
  }
}
