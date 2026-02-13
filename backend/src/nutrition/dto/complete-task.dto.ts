import { IsNotEmpty, IsBoolean, IsDateString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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
}
