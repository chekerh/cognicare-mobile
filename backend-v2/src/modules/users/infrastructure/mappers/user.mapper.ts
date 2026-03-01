/**
 * User Mapper - Infrastructure Layer
 */
import { Types } from 'mongoose';
import { UserEntity, UserRole } from '../../domain/entities/user.entity';
import { UserDocument } from '../persistence/mongo/user.schema';

export class UserMapper {
  static toDomain(doc: UserDocument): UserEntity {
    return UserEntity.reconstitute(doc._id.toString(), {
      email: doc.email,
      passwordHash: doc.passwordHash,
      role: doc.role as UserRole,
      firstName: doc.firstName,
      lastName: doc.lastName,
      phone: doc.phone,
      profileImageUrl: doc.profileImageUrl,
      organizationId: doc.organizationId?.toString(),
      isEmailVerified: doc.isEmailVerified,
      blockedUserIds: doc.blockedUserIds?.map(id => id.toString()),
      deletedAt: doc.deletedAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: UserEntity): Record<string, unknown> {
    return {
      email: entity.email,
      passwordHash: entity.passwordHash,
      role: entity.role,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phone: entity.phone,
      profileImageUrl: entity.profileImageUrl,
      organizationId: entity.organizationId ? new Types.ObjectId(entity.organizationId) : undefined,
      isEmailVerified: entity.isEmailVerified,
      blockedUserIds: entity.blockedUserIds?.map(id => new Types.ObjectId(id)),
      deletedAt: entity.deletedAt,
    };
  }
}
