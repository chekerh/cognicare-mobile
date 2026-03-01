/**
 * Get Children by Specialist Use Case - Application Layer
 * 
 * Retrieves private children added by a specialist.
 */
import { Inject, Injectable } from '@nestjs/common';
import { Result } from '@/core/application';
import { IChildRepository, CHILD_REPOSITORY_TOKEN } from '../../domain/repositories/child.repository.interface';
import { ChildOutputDto } from '../dto/child.dto';
import { ChildMapper } from '../../infrastructure/mappers/child.mapper';

export interface GetChildrenBySpecialistInput {
  specialistId: string;
}

export type GetChildrenBySpecialistOutput = Result<ChildOutputDto[], Error>;

@Injectable()
export class GetChildrenBySpecialistUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepository: IChildRepository,
  ) {}

  async execute(input: GetChildrenBySpecialistInput): Promise<GetChildrenBySpecialistOutput> {
    try {
      const { specialistId } = input;

      // Fetch children created by this specialist
      const children = await this.childRepository.findBySpecialistId(specialistId);

      return Result.ok(children.map(ChildMapper.toOutputDto));
    } catch (error) {
      return Result.fail(error instanceof Error ? error : new Error(String(error)));
    }
  }
}
