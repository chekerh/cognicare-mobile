import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsEnum,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AddChildDto {
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
  gender!: 'male' | 'female' | 'other';

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
    description: 'Current medications',
    example: 'Medication A, Medication B',
  })
  @IsOptional()
  @IsString()
  medications?: string;

  @ApiPropertyOptional({
    description: 'Additional notes about the child',
    example: 'Requires special attention during activities',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
