/**
 * Create Child for Family Use Case - Application Layer
 * 
 * This use case handles creating a child for a family user.
 * It has a single responsibility and depends only on:
 * - Repository interfaces (not implementations)
 * - Domain entities
 * 
 * NO framework dependencies (no NestJS decorators, no Mongoose).
 */
import { Inject, Injectable } from '@nestjs/common';
import { Result } from '@/core/application';
import { 
  EntityNotFoundException, 
  ForbiddenAccessException,
  BusinessRuleViolationException 
} from '@/core/domain';
import { ChildEntity, Gender } from '../../domain/entities/child.entity';
import { IChildRepository, CHILD_REPOSITORY_TOKEN } from '../../domain/repositories/child.repository.interface';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '@/modules/users/domain/repositories/user.repository.interface';
import { AddChildInputDto, ChildOutputDto } from '../dto/child.dto';
import { ChildMapper } from '../../infrastructure/mappers/child.mapper';

export interface CreateChildForFamilyInput {
  familyId: string;
  requesterId: string;
  childData: AddChildInputDto;
}

export type CreateChildForFamilyOutput = Result<ChildOutputDto, Error>;

@Injectable()
export class CreateChildForFamilyUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepository: IChildRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepository: IUserRepository,
  ) {}

  async execute(input: CreateChildForFamilyInput): Promise<CreateChildForFamilyOutput> {
    try {
      const { familyId, requesterId, childData } = input;

      // Business Rule: Only the family user can add children to their own profile
      if (requesterId !== familyId) {
        return Result.fail(
          new ForbiddenAccessException('You can only add children to your own profile')
        );
      }

      // Verify the user exists and is a family
      const family = await this.userRepository.findById(familyId);
      if (!family) {
        return Result.fail(new EntityNotFoundException('User', familyId));
      }

      if (family.role !== 'family') {
        return Result.fail(
          new BusinessRuleViolationException('Only family accounts can add children')
        );
      }

      // Create the child entity
      const child = ChildEntity.create({
        fullName: childData.fullName.trim(),
        dateOfBirth: new Date(childData.dateOfBirth),
        gender: childData.gender as Gender,
        diagnosis: childData.diagnosis?.trim(),
        medicalHistory: childData.medicalHistory?.trim(),
        allergies: childData.allergies?.trim(),
        medications: childData.medications?.trim(),
        notes: childData.notes?.trim(),
        parentId: familyId,
        organizationId: family.organizationId,
        addedByOrganizationId: family.organizationId,
        lastModifiedBy: requesterId,
      });

      // Persist the child
      const savedChild = await this.childRepository.save(child);

      // Return the output DTO
      return Result.ok(ChildMapper.toOutputDto(savedChild));
    } catch (error) {
      return Result.fail(error instanceof Error ? error : new Error(String(error)));
    }
  }
}
