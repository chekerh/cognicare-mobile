import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  MinLength,
  IsNotEmpty,
  IsOptional,
} from 'class-validator';

export class InviteOrganizationLeaderDto {
  @ApiProperty({ example: 'CogniCare Care Center' })
  @IsString()
  @IsNotEmpty()
  organizationName: string;

  @ApiProperty({ example: 'John Smith' })
  @IsString()
  @IsNotEmpty()
  leaderFullName: string;

  @ApiProperty({ example: 'leader@organization.com' })
  @IsEmail()
  leaderEmail: string;

  @ApiProperty({ example: '+1234567890' })
  @IsString()
  @IsOptional()
  leaderPhone?: string;

  @ApiProperty({ example: 'SecurePassword123!' })
  @IsString()
  @MinLength(8)
  leaderPassword: string;
}
