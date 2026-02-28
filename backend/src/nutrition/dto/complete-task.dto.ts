import {
  IsNotEmpty,
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CompleteTaskDto {
  @ApiProperty({
    description: 'Reminder ID',
    example: '507f1f77bcf86cd799439011',
  })
  @IsNotEmpty()
  reminderId!: string;

  @ApiProperty({
    description: 'Completion status',
    example: true,
  })
  @IsNotEmpty()
  @IsBoolean()
  completed!: boolean;

  @ApiProperty({
    description: 'Date of completion (ISO format)',
    example: '2026-02-13T14:30:00.000Z',
  })
  @IsNotEmpty()
  @IsDateString()
  date!: string;

  @ApiPropertyOptional({
    description: 'Optional parent feedback about how the task went',
    example: 'Task was too complex, child lost focus quickly.',
  })
  @IsOptional()
  @IsString()
  feedback?: string;
}
