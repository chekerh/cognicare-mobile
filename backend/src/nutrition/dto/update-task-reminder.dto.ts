import { PartialType } from '@nestjs/swagger';
import { CreateTaskReminderDto } from './create-task-reminder.dto';
import { IsOptional, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateTaskReminderDto extends PartialType(CreateTaskReminderDto) {
  @ApiPropertyOptional({
    description: 'Whether this reminder is active',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
