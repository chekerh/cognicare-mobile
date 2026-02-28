import {
  IsEmail,
  IsOptional,
  IsString,
  IsEnum,
  IsNumber,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiPropertyOptional({
    description: "User's full name",
    example: 'John Doe',
  })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({
    description: "User's email address",
    example: 'john.doe@example.com',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: "User's phone number",
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    description: "User's role in the platform",
    example: 'family',
    enum: ['family', 'doctor', 'volunteer', 'admin'],
  })
  @IsOptional()
  @IsEnum(['family', 'doctor', 'volunteer', 'admin'])
  role?: 'family' | 'doctor' | 'volunteer' | 'admin';

  @ApiPropertyOptional({
    description: "User's profile picture URL",
    example: 'https://example.com/profile.jpg',
  })
  @IsOptional()
  @IsString()
  profilePic?: string;

  @ApiPropertyOptional({
    description: 'Cabinet address (for healthcare professionals in Tunisia)',
  })
  @IsOptional()
  @IsString()
  officeAddress?: string;

  @ApiPropertyOptional({
    description: 'Cabinet city (e.g. Tunis, Sfax)',
  })
  @IsOptional()
  @IsString()
  officeCity?: string;

  @ApiPropertyOptional({ description: 'Cabinet latitude' })
  @IsOptional()
  @IsNumber()
  officeLat?: number;

  @ApiPropertyOptional({ description: 'Cabinet longitude' })
  @IsOptional()
  @IsNumber()
  officeLng?: number;
}
