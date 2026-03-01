import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class ApproveTrainingCourseDto {
  @IsBoolean()
  approved: boolean;

  @IsOptional()
  @IsString()
  professionalComments?: string;
}
