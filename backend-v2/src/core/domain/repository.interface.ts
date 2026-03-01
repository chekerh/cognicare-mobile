/**
 * Generic Repository Interface.
 * All repository interfaces in the domain layer should extend this.
 * This defines the contract that infrastructure implementations must fulfill.
 */
export interface IRepository<T, ID = string> {
  /**
   * Find an entity by its ID.
   */
  findById(id: ID): Promise<T | null>;

  /**
   * Save an entity (create or update).
   */
  save(entity: T): Promise<T>;

  /**
   * Delete an entity by ID.
   */
  delete(id: ID): Promise<boolean>;

  /**
   * Check if an entity exists by ID.
   */
  exists(id: ID): Promise<boolean>;
}

/**
 * Extended repository interface with common query methods.
 */
export interface IExtendedRepository<T, ID = string> extends IRepository<T, ID> {
  /**
   * Find all entities.
   */
  findAll(): Promise<T[]>;

  /**
   * Find entities with pagination.
   */
  findWithPagination(
    page: number,
    limit: number,
    filter?: Partial<T>,
  ): Promise<{ data: T[]; total: number; page: number; limit: number }>;

  /**
   * Count entities matching a filter.
   */
  count(filter?: Partial<T>): Promise<number>;
}
