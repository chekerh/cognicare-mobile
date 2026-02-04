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
  fullName: string;

  @ApiProperty({
    description: "User's email address",
    example: 'john.doe@example.com',
    format: 'email',
  })
  @IsNotEmpty()
  @IsEmail()
  email: string;

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
  password: string;

  @ApiProperty({
    description: "User's role in the platform",
    example: 'family',
    enum: ['family', 'doctor', 'volunteer', 'organization_leader'],
  })
  @IsNotEmpty()
  @IsEnum(['family', 'doctor', 'volunteer', 'organization_leader'])
  role: 'family' | 'doctor' | 'volunteer' | 'organization_leader';

  @ApiProperty({
    description: '6-digit verification code sent to email',
    example: '123456',
  })
  @IsNotEmpty()
  @IsString()
  verificationCode: string;
}
