/**
 * Update Child Use Case - Application Layer
 * 
 * Updates child information with authorization checks.
 */
import { Inject, Injectable } from '@nestjs/common';
import { Result } from '@/core/application';
import { 
  EntityNotFoundException, 
  ForbiddenAccessException 
} from '@/core/domain';
import { IChildRepository, CHILD_REPOSITORY_TOKEN } from '../../domain/repositories/child.repository.interface';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '@/modules/users/domain/repositories/user.repository.interface';
import { UpdateChildInputDto } from '../dto/update-child.dto';
import { ChildOutputDto } from '../dto/child.dto';
import { ChildMapper } from '../../infrastructure/mappers/child.mapper';
import { Gender } from '../../domain/entities/child.entity';

export interface UpdateChildInput {
  childId: string;
  requesterId: string;
  requesterRole: string;
  updateData: UpdateChildInputDto;
}

export type UpdateChildOutput = Result<ChildOutputDto, Error>;

@Injectable()
export class UpdateChildUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepository: IChildRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepository: IUserRepository,
  ) {}

  async execute(input: UpdateChildInput): Promise<UpdateChildOutput> {
    try {
      const { childId, requesterId, requesterRole, updateData } = input;

      // Find the child
      const child = await this.childRepository.findById(childId);
      if (!child) {
        return Result.fail(new EntityNotFoundException('Child', childId));
      }

      // Authorization: parent, specialist owner, or org staff can update
      const isParent = child.parentId === requesterId;
      const isSpecialist = child.specialistId === requesterId;
      const isStaffRole = ['doctor', 'psychologist', 'speech_therapist', 
                           'occupational_therapist', 'volunteer', 'other'].includes(requesterRole);

      if (!isParent && !isSpecialist && !isStaffRole) {
        return Result.fail(
          new ForbiddenAccessException('Not authorized to update this child')
        );
      }

      // Update the child entity
      child.update({
        fullName: updateData.fullName,
        dateOfBirth: updateData.dateOfBirth ? new Date(updateData.dateOfBirth) : undefined,
        gender: updateData.gender as Gender | undefined,
        diagnosis: updateData.diagnosis,
        medicalHistory: updateData.medicalHistory,
        allergies: updateData.allergies,
        medications: updateData.medications,
        notes: updateData.notes,
      }, requesterId);

      // Persist changes
      const savedChild = await this.childRepository.save(child);

      return Result.ok(ChildMapper.toOutputDto(savedChild));
    } catch (error) {
      return Result.fail(error instanceof Error ? error : new Error(String(error)));
    }
  }
}
