import { IsEnum, IsOptional, IsString, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateApplicationMeDto {
  @ApiPropertyOptional({ enum: ['speech_therapist', 'occupational_therapist', 'psychologist', 'doctor', 'ergotherapist', 'caregiver', 'organization_leader', 'other'] })
  @IsOptional()
  @IsString()
  careProviderType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  specialty?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  organizationName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  organizationRole?: string;
}

export class ReviewApplicationDto {
  @ApiProperty({ enum: ['approved', 'denied'] })
  @IsEnum(['approved', 'denied'])
  decision!: 'approved' | 'denied';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  deniedReason?: string;
}

export class AssignTaskDto {
  @ApiProperty()
  @IsString()
  volunteerId!: string;

  @ApiProperty()
  @IsString()
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dueDate?: string;
}
