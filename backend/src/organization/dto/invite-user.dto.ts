import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsOptional } from 'class-validator';

export class InviteUserDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: 'John Doe', required: false })
  @IsNotEmpty()
  @IsOptional()
  fullName?: string;

  @ApiProperty({ example: '+1234567890', required: false })
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: 'psychologist', required: false })
  @IsOptional()
  role?: string;
}
