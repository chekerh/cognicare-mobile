import { IsEmail, IsNotEmpty, IsOptional, IsString, IsEnum, IsPhoneNumber, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SignupDto {
  @ApiProperty({
    description: 'User\'s full name',
    example: 'John Doe',
    minLength: 1
  })
  @IsNotEmpty()
  @IsString()
  fullName: string;

  @ApiProperty({
    description: 'User\'s email address',
    example: 'john.doe@example.com',
    format: 'email'
  })
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @ApiPropertyOptional({
    description: 'User\'s phone number',
    example: '+1234567890'
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({
    description: 'User\'s password (minimum 6 characters)',
    example: 'securePassword123',
    minLength: 6
  })
  @IsNotEmpty()
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({
    description: 'User\'s role in the platform',
    example: 'family',
    enum: ['family', 'doctor', 'volunteer']
  })
  @IsNotEmpty()
  @IsEnum(['family', 'doctor', 'volunteer'])
  role: 'family' | 'doctor' | 'volunteer';
}