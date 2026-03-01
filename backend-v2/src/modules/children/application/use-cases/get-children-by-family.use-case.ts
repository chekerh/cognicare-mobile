/**
 * Get Children by Family Use Case - Application Layer
 * 
 * Retrieves children for a family with authorization checks.
 */
import { Inject, Injectable } from '@nestjs/common';
import { Result } from '@/core/application';
import { 
  EntityNotFoundException, 
  ForbiddenAccessException,
  BusinessRuleViolationException 
} from '@/core/domain';
import { IChildRepository, CHILD_REPOSITORY_TOKEN } from '../../domain/repositories/child.repository.interface';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '@/modules/users/domain/repositories/user.repository.interface';
import { IOrganizationRepository, ORGANIZATION_REPOSITORY_TOKEN } from '@/modules/organization/domain/repositories/organization.repository.interface';
import { ChildOutputDto } from '../dto/child.dto';
import { ChildMapper } from '../../infrastructure/mappers/child.mapper';

export interface GetChildrenByFamilyInput {
  familyId: string;
  requesterId: string;
}

export type GetChildrenByFamilyOutput = Result<ChildOutputDto[], Error>;

@Injectable()
export class GetChildrenByFamilyUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepository: IChildRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepository: IUserRepository,
    @Inject(ORGANIZATION_REPOSITORY_TOKEN)
    private readonly organizationRepository: IOrganizationRepository,
  ) {}

  async execute(input: GetChildrenByFamilyInput): Promise<GetChildrenByFamilyOutput> {
    try {
      const { familyId, requesterId } = input;

      // Verify the family user exists
      const family = await this.userRepository.findById(familyId);
      if (!family) {
        return Result.fail(new EntityNotFoundException('Family', familyId));
      }

      if (family.role !== 'family') {
        return Result.fail(
          new BusinessRuleViolationException('User is not a family')
        );
      }

      // Authorization check: requester must be the family OR an org leader of the family's org
      if (familyId !== requesterId) {
        const org = await this.organizationRepository.findByLeaderId(requesterId);
        if (!org) {
          return Result.fail(
            new ForbiddenAccessException('Not allowed to list this family\'s children')
          );
        }
        if (family.organizationId !== org.id) {
          return Result.fail(
            new ForbiddenAccessException('Family not in your organization')
          );
        }
      }

      // Fetch children
      const children = await this.childRepository.findByParentId(familyId);

      return Result.ok(children.map(ChildMapper.toOutputDto));
    } catch (error) {
      return Result.fail(error instanceof Error ? error : new Error(String(error)));
    }
  }
}
