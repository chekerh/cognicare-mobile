/**
 * Email Verification Repository Interface - Domain Layer
 */
import { IRepository } from '../../../../core/domain/repository.interface';
import { EmailVerificationEntity } from '../entities/email-verification.entity';

export const EMAIL_VERIFICATION_REPOSITORY_TOKEN = Symbol('IEmailVerificationRepository');

export interface IEmailVerificationRepository extends IRepository<EmailVerificationEntity> {
  findByEmail(email: string): Promise<EmailVerificationEntity | null>;
  deleteByEmail(email: string): Promise<boolean>;
  deleteExpired(): Promise<number>;
}
