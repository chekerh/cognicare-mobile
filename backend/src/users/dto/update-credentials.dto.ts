import { IsEmail, IsOptional, IsString, MinLength, IsNotEmpty } from 'class-validator';
import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';

export class UpdatePasswordDto {
  @ApiPropertyOptional({
    description: 'Current password',
    example: 'oldPassword123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  currentPassword: string;

  @ApiPropertyOptional({
    description: 'New password (minimum 6 characters)',
    example: 'newPassword123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class RequestEmailChangeDto {
  @ApiProperty({
    description: 'New email address',
    example: 'newemail@example.com',
  })
  @IsEmail()
  @IsNotEmpty()
  newEmail: string;

  @ApiProperty({
    description: 'Current password for verification',
    example: 'password123',
  })
  @IsString()
  @IsNotEmpty()
  password: string;
}

export class VerifyEmailChangeDto {
  @ApiProperty({
    description: '6-digit verification code sent to new email',
    example: '123456',
  })
  @IsString()
  @IsNotEmpty()
  code: string;
}

export class UpdateEmailDto {
  @ApiPropertyOptional({
    description: 'New email address',
    example: 'newemail@example.com',
  })
  @IsEmail()
  newEmail: string;

  @ApiPropertyOptional({
    description: 'Current password for verification',
    example: 'password123',
  })
  @IsString()
  @MinLength(6)
  password: string;
}
