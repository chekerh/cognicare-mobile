/**
 * Update Child DTO - Application Layer
 */
import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { GenderInput } from './child.dto';

export class UpdateChildInputDto {
  @ApiPropertyOptional({
    description: 'Child full name',
    example: 'John Doe Jr.',
  })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({
    description: 'Child date of birth',
    example: '2015-05-15',
    type: String,
    format: 'date',
  })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({
    description: 'Child gender',
    example: 'male',
    enum: ['male', 'female', 'other'],
  })
  @IsOptional()
  @IsEnum(['male', 'female', 'other'])
  gender?: GenderInput;

  @ApiPropertyOptional({
    description: 'Child diagnosis or medical condition',
    example: 'Autism Spectrum Disorder',
  })
  @IsOptional()
  @IsString()
  diagnosis?: string;

  @ApiPropertyOptional({
    description: 'Child medical history',
    example: 'Previous surgeries, chronic conditions',
  })
  @IsOptional()
  @IsString()
  medicalHistory?: string;

  @ApiPropertyOptional({
    description: 'Child allergies',
    example: 'Peanuts, dairy',
  })
  @IsOptional()
  @IsString()
  allergies?: string;

  @ApiPropertyOptional({
    description: 'Child medications',
    example: 'Ritalin 10mg daily',
  })
  @IsOptional()
  @IsString()
  medications?: string;

  @ApiPropertyOptional({
    description: 'Additional notes about the child',
    example: 'Prefers morning sessions',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
