import {
  IsEmail,
  IsNotEmpty,
  IsString,
  IsEnum,
  IsOptional,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateStaffDto {
  @ApiProperty({
    description: "Staff member's full name",
    example: 'Dr. Sarah Johnson',
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: "Staff member's email address",
    example: 'sarah.johnson@example.com',
  })
  @IsNotEmpty()
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({
    description: "Staff member's phone number",
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    description: 'Temporary password (user should change on first login)',
    example: 'TempPass123!',
    minLength: 6,
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({
    description: "Staff member's role",
    example: 'psychologist',
    enum: [
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'doctor',
      'volunteer',
      'other',
    ],
  })
  @IsNotEmpty()
  @IsEnum([
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'other',
  ])
  role!:
    | 'psychologist'
    | 'speech_therapist'
    | 'occupational_therapist'
    | 'doctor'
    | 'volunteer'
    | 'other';
}
