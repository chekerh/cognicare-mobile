/**
 * User Repository Interface - Domain Layer
 */
import { IExtendedRepository } from '@/core/domain';
import { UserEntity, UserRole } from '../entities/user.entity';

export interface IUserRepository extends IExtendedRepository<UserEntity, string> {
  findByEmail(email: string): Promise<UserEntity | null>;
  findByRole(role: UserRole): Promise<UserEntity[]>;
  findByOrganizationId(organizationId: string): Promise<UserEntity[]>;
  findByIds(ids: string[]): Promise<UserEntity[]>;
  countByRole(role: UserRole): Promise<number>;
  countByOrganizationId(organizationId: string): Promise<number>;
}

export const USER_REPOSITORY_TOKEN = Symbol('IUserRepository');
