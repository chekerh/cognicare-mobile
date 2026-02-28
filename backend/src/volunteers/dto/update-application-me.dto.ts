import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

const CARE_PROVIDER_TYPE_ENUM = [
  'speech_therapist',
  'occupational_therapist',
  'psychologist',
  'doctor',
  'ergotherapist',
  'caregiver',
  'organization_leader',
  'other',
] as const;

export type CareProviderTypeDto = (typeof CARE_PROVIDER_TYPE_ENUM)[number];

export class UpdateApplicationMeDto {
  @ApiPropertyOptional({
    description:
      'Care Provider type (Speech Therapist, Occupational Therapist, Psychologist, Doctor, Ergotherapist, Caregiver, Other)',
    enum: CARE_PROVIDER_TYPE_ENUM,
  })
  @IsOptional()
  @IsEnum(CARE_PROVIDER_TYPE_ENUM)
  careProviderType?: CareProviderTypeDto;

  @ApiPropertyOptional({
    description: 'Specialty or area of expertise (e.g. for healthcare providers)',
    example: 'Orthophonie',
  })
  @IsOptional()
  @IsString()
  specialty?: string;

  @ApiPropertyOptional({
    description: 'Organization name (for organization leaders)',
    example: 'Hope Care Foundation',
  })
  @IsOptional()
  @IsString()
  organizationName?: string;

  @ApiPropertyOptional({
    description: 'Role or title in the organization',
    example: 'Director',
  })
  @IsOptional()
  @IsString()
  organizationRole?: string;
}
