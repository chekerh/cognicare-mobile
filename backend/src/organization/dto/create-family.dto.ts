import {
  IsEmail,
  IsNotEmpty,
  IsString,
  IsOptional,
  MinLength,
  ValidateNested,
  IsArray,
  IsDateString,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

class ChildDto {
  @ApiProperty({
    description: "Child's full name",
    example: 'Emma Smith',
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
  })
  @IsOptional()
  @IsString()
  diagnosis?: string;

  @ApiPropertyOptional({
    description: 'Medical history',
  })
  @IsOptional()
  @IsString()
  medicalHistory?: string;

  @ApiPropertyOptional({
    description: 'Known allergies',
  })
  @IsOptional()
  @IsString()
  allergies?: string;

  @ApiPropertyOptional({
    description: 'Current medications',
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

export class CreateFamilyDto {
  @ApiProperty({
    description: "Parent's full name",
    example: 'John Smith',
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: "Parent's email address",
    example: 'john.smith@example.com',
  })
  @IsNotEmpty()
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({
    description: "Parent's phone number",
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    description: 'Temporary password for parent account',
    example: 'TempPass123!',
    minLength: 6,
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiPropertyOptional({
    description: 'Array of children to create for this family',
    type: [ChildDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChildDto)
  children?: ChildDto[];
}
