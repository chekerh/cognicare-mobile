import {
  IsNotEmpty,
  IsString,
  IsEnum,
  IsOptional,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateChildDto {
  @ApiProperty({
    description: "Child's full name",
    example: 'Sarah Doe',
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: "Child's date of birth",
    example: '2018-05-15',
  })
  @IsNotEmpty()
  @IsDateString()
  dateOfBirth!: string;

  @ApiProperty({
    description: "Child's gender",
    example: 'female',
    enum: ['male', 'female', 'other'],
  })
  @IsNotEmpty()
  @IsEnum(['male', 'female', 'other'])
  gender!: 'male' | 'female' | 'other';

  @ApiPropertyOptional({
    description: 'Medical diagnosis',
    example: 'Autism Spectrum Disorder',
  })
  @IsOptional()
  @IsString()
  diagnosis?: string;

  @ApiPropertyOptional({
    description: 'Medical history',
    example: 'Diagnosed at age 3...',
  })
  @IsOptional()
  @IsString()
  medicalHistory?: string;

  @ApiPropertyOptional({
    description: 'Known allergies',
    example: 'Peanuts, dairy',
  })
  @IsOptional()
  @IsString()
  allergies?: string;

  @ApiPropertyOptional({
    description: 'Current medications',
    example: 'Risperidone 0.5mg daily',
  })
  @IsOptional()
  @IsString()
  medications?: string;

  @ApiPropertyOptional({
    description: 'Additional notes',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
