/**
 * Email Verification Mapper - Infrastructure Layer
 */
import { EmailVerificationEntity } from '../../domain/entities/email-verification.entity';
import { EmailVerificationDocument } from '../persistence/mongo/email-verification.schema';

export class EmailVerificationMapper {
  static toDomain(doc: EmailVerificationDocument): EmailVerificationEntity {
    return EmailVerificationEntity.reconstitute(doc._id.toString(), {
      email: doc.email,
      codeHash: doc.codeHash,
      expiresAt: doc.expiresAt,
      createdAt: doc.createdAt,
    });
  }

  static toPersistence(entity: EmailVerificationEntity): Record<string, unknown> {
    return {
      email: entity.email,
      codeHash: entity.codeHash,
      expiresAt: entity.expiresAt,
    };
  }
}
