import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsEnum,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SignupDto {
  @ApiProperty({
    description: "User's full name",
    example: 'John Doe',
    minLength: 1,
  })
  @IsNotEmpty()
  @IsString()
  fullName!: string;

  @ApiProperty({
    description: "User's email address",
    example: 'john.doe@example.com',
    format: 'email',
  })
  @IsNotEmpty()
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({
    description: "User's phone number",
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    description: "User's password (minimum 6 characters)",
    example: 'securePassword123',
    minLength: 6,
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiProperty({
    description:
      "User's role in the platform. Note: Specialized therapy roles (psychologist, speech_therapist, occupational_therapist, other) can only be assigned by organization leaders via staff management - they cannot self-signup.",
    example: 'family',
    enum: ['family', 'doctor', 'volunteer', 'organization_leader'],
  })
  @IsNotEmpty()
  @IsEnum(['family', 'doctor', 'volunteer', 'organization_leader'])
  role!: 'family' | 'doctor' | 'volunteer' | 'organization_leader';

  @ApiPropertyOptional({
    description:
      'Organization name (required when role is organization_leader)',
    example: 'Hope Care Foundation',
  })
  @IsOptional()
  @IsString()
  organizationName?: string;

  @ApiProperty({
    description: '6-digit verification code sent to email',
    example: '123456',
  })
  @IsNotEmpty()
  @IsString()
  verificationCode!: string;
}
