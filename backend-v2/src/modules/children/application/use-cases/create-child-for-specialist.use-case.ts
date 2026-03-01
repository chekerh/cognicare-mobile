/**
 * Create Child for Specialist Use Case - Application Layer
 * 
 * Handles creating a private child profile for a specialist.
 */
import { Inject, Injectable } from '@nestjs/common';
import { Result } from '@/core/application';
import { ChildEntity, Gender } from '../../domain/entities/child.entity';
import { IChildRepository, CHILD_REPOSITORY_TOKEN } from '../../domain/repositories/child.repository.interface';
import { AddChildInputDto, ChildOutputDto } from '../dto/child.dto';
import { ChildMapper } from '../../infrastructure/mappers/child.mapper';

export interface CreateChildForSpecialistInput {
  specialistId: string;
  childData: AddChildInputDto;
}

export type CreateChildForSpecialistOutput = Result<ChildOutputDto, Error>;

@Injectable()
export class CreateChildForSpecialistUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepository: IChildRepository,
  ) {}

  async execute(input: CreateChildForSpecialistInput): Promise<CreateChildForSpecialistOutput> {
    try {
      const { specialistId, childData } = input;

      // Create the child entity with specialist ownership
      const child = ChildEntity.create({
        fullName: childData.fullName.trim(),
        dateOfBirth: new Date(childData.dateOfBirth),
        gender: childData.gender as Gender,
        diagnosis: childData.diagnosis?.trim(),
        medicalHistory: childData.medicalHistory?.trim(),
        allergies: childData.allergies?.trim(),
        medications: childData.medications?.trim(),
        notes: childData.notes?.trim(),
        specialistId: specialistId,
        addedBySpecialistId: specialistId,
        lastModifiedBy: specialistId,
      });

      // Persist the child
      const savedChild = await this.childRepository.save(child);

      return Result.ok(ChildMapper.toOutputDto(savedChild));
    } catch (error) {
      return Result.fail(error instanceof Error ? error : new Error(String(error)));
    }
  }
}
