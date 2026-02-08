import {
  IsEmail,
  IsNotEmpty,
  IsString,
  IsEnum,
  MinLength,
  IsOptional,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateStaffDto {
  @ApiProperty({
    description: 'Staff member full name',
    example: 'Dr. Jane Smith',
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: 'Staff member email address',
    example: 'jane.smith@example.com',
    format: 'email',
  })
  @IsNotEmpty()
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({
    description: 'Staff member phone number',
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    description: 'Staff member password (minimum 6 characters)',
    example: 'securePassword123',
    minLength: 6,
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({
    description: 'Staff member role',
    enum: [
      'doctor',
      'volunteer',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
    ],
    example: 'doctor',
  })
  @IsNotEmpty()
  @IsEnum([
    'doctor',
    'volunteer',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  ])
  role!: string;
}
