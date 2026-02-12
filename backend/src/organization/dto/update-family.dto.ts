import { IsString, IsOptional, IsEmail } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateFamilyDto {
  @ApiPropertyOptional({
    description: 'Family member full name',
    example: 'Jane Doe',
  })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({
    description: 'Family member email',
    example: 'jane.doe@example.com',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'Family member phone number',
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  phone?: string;
}
