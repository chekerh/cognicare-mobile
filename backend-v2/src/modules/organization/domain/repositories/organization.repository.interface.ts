/**
 * Organization Repository Interface - Domain Layer
 */
import { IRepository } from '../../../../core/domain/repository.interface';
import { OrganizationEntity } from '../entities/organization.entity';

export const ORGANIZATION_REPOSITORY_TOKEN = Symbol('IOrganizationRepository');

export interface IOrganizationRepository extends IRepository<OrganizationEntity> {
  findByLeaderId(leaderId: string): Promise<OrganizationEntity | null>;
  findByStaffId(staffId: string): Promise<OrganizationEntity | null>;
  findPending(): Promise<OrganizationEntity[]>;
  findApproved(): Promise<OrganizationEntity[]>;
}
