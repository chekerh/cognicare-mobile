/**
 * Add Child DTO - Application Layer
 * 
 * Input DTO for creating a new child.
 * DTOs are simple data structures for transferring data across layers.
 */
import { IsNotEmpty, IsString, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type GenderInput = 'male' | 'female' | 'other';

export class AddChildInputDto {
  @ApiProperty({
    description: 'Child full name',
    example: 'John Doe Jr.',
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: 'Child date of birth',
    example: '2015-05-15',
    type: String,
    format: 'date',
  })
  @IsNotEmpty()
  @IsDateString()
  dateOfBirth!: string;

  @ApiProperty({
    description: 'Child gender',
    example: 'male',
    enum: ['male', 'female', 'other'],
  })
  @IsNotEmpty()
  @IsEnum(['male', 'female', 'other'])
  gender!: GenderInput;

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

/**
 * Output DTO for child data.
 */
export class ChildOutputDto {
  @ApiProperty({ description: 'Child ID' })
  id!: string;

  @ApiProperty({ description: 'Child full name' })
  fullName!: string;

  @ApiProperty({ description: 'Date of birth (YYYY-MM-DD)' })
  dateOfBirth!: string;

  @ApiProperty({ description: 'Gender', enum: ['male', 'female', 'other'] })
  gender!: GenderInput;

  @ApiPropertyOptional({ description: 'Diagnosis' })
  diagnosis?: string;

  @ApiPropertyOptional({ description: 'Medical history' })
  medicalHistory?: string;

  @ApiPropertyOptional({ description: 'Allergies' })
  allergies?: string;

  @ApiPropertyOptional({ description: 'Medications' })
  medications?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  notes?: string;

  @ApiPropertyOptional({ description: 'Parent user ID' })
  parentId?: string;

  @ApiPropertyOptional({ description: 'Organization ID' })
  organizationId?: string;

  @ApiPropertyOptional({ description: 'Specialist ID' })
  specialistId?: string;

  @ApiPropertyOptional({ description: 'Created timestamp' })
  createdAt?: string;

  @ApiPropertyOptional({ description: 'Updated timestamp' })
  updatedAt?: string;
}
