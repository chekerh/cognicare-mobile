import { IsString, IsOptional, IsEmail, IsEnum } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateStaffDto {
  @ApiPropertyOptional({
    description: 'Staff member full name',
    example: 'Dr. John Smith',
  })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({
    description: 'Staff member email',
    example: 'john.smith@example.com',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'Staff member phone number',
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    description: 'Staff member role',
    enum: [
      'doctor',
      'volunteer',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ],
    example: 'psychologist',
  })
  @IsOptional()
  @IsEnum([
    'doctor',
    'volunteer',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'other',
  ])
  role?: string;
}
