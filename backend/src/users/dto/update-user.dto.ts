import { IsEmail, IsOptional, IsString, IsEnum } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiPropertyOptional({
    description: 'User\'s full name',
    example: 'John Doe',
  })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({
    description: 'User\'s email address',
    example: 'john.doe@example.com',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'User\'s phone number',
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    description: 'User\'s role in the platform',
    example: 'family',
    enum: ['family', 'doctor', 'volunteer'],
  })
  @IsOptional()
  @IsEnum(['family', 'doctor', 'volunteer'])
  role?: 'family' | 'doctor' | 'volunteer';

  @ApiPropertyOptional({
    description: 'User\'s profile picture URL',
    example: 'https://example.com/profile.jpg',
  })
  @IsOptional()
  @IsString()
  profilePic?: string;
}
