/**
 * Refresh Token Repository Interface - Domain Layer
 */
import { IRepository } from '../../../../core/domain/repository.interface';
import { RefreshTokenEntity } from '../entities/refresh-token.entity';

export const REFRESH_TOKEN_REPOSITORY_TOKEN = Symbol('IRefreshTokenRepository');

export interface IRefreshTokenRepository extends IRepository<RefreshTokenEntity> {
  findByUserId(userId: string): Promise<RefreshTokenEntity[]>;
  findByTokenHash(tokenHash: string): Promise<RefreshTokenEntity | null>;
  deleteByUserId(userId: string): Promise<number>;
  deleteExpired(): Promise<number>;
}
