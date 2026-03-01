/**
 * Child Repository Interface - Domain Layer
 * 
 * This interface defines the contract for child persistence.
 * The domain layer knows nothing about Mongoose, MongoDB, or any database.
 * Infrastructure layer provides the concrete implementation.
 */
import { IExtendedRepository } from '@/core/domain';
import { ChildEntity } from '../entities/child.entity';

export interface IChildRepository extends IExtendedRepository<ChildEntity, string> {
  /**
   * Find children by parent ID.
   */
  findByParentId(parentId: string): Promise<ChildEntity[]>;

  /**
   * Find children by specialist ID.
   */
  findBySpecialistId(specialistId: string): Promise<ChildEntity[]>;

  /**
   * Find children by organization ID.
   */
  findByOrganizationId(organizationId: string): Promise<ChildEntity[]>;

  /**
   * Find children including soft-deleted ones.
   */
  findByIdIncludingDeleted(id: string): Promise<ChildEntity | null>;

  /**
   * Bulk create children.
   */
  createMany(children: ChildEntity[]): Promise<ChildEntity[]>;

  /**
   * Get children count by organization.
   */
  countByOrganizationId(organizationId: string): Promise<number>;

  /**
   * Get children count by specialist.
   */
  countBySpecialistId(specialistId: string): Promise<number>;
}

/**
 * Injection token for the repository.
 * Used for dependency injection binding.
 */
export const CHILD_REPOSITORY_TOKEN = Symbol('IChildRepository');
