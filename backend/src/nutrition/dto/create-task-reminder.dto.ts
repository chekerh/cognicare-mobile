import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsEnum,
  IsBoolean,
  IsNumber,
  IsArray,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ReminderType,
  ReminderFrequency,
} from '../schemas/task-reminder.schema';

export class CreateTaskReminderDto {
  @ApiProperty({
    description: 'Child ID for this reminder',
    example: '507f1f77bcf86cd799439011',
  })
  @IsNotEmpty()
  @IsString()
  childId!: string;

  @ApiProperty({
    description: 'Type of reminder',
    enum: ReminderType,
    example: ReminderType.WATER,
  })
  @IsNotEmpty()
  @IsEnum(ReminderType)
  type!: ReminderType;

  @ApiProperty({
    description: 'Title of the reminder',
    example: 'Drink Water',
  })
  @IsNotEmpty()
  @IsString()
  title!: string;

  @ApiPropertyOptional({
    description: 'Description or instructions',
    example: 'Remember to drink a full glass of water',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'Icon emoji or name',
    example: '💧',
  })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional({
    description: 'Color hex code',
    example: '#3B82F6',
  })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiProperty({
    description: 'Frequency of reminder',
    enum: ReminderFrequency,
    example: ReminderFrequency.INTERVAL,
  })
  @IsNotEmpty()
  @IsEnum(ReminderFrequency)
  frequency!: ReminderFrequency;

  @ApiPropertyOptional({
    description: 'Specific times for the reminder (HH:MM format)',
    example: ['08:00', '14:30'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  times?: string[];

  @ApiPropertyOptional({
    description: 'Interval in minutes (for interval frequency)',
    example: 120,
  })
  @IsOptional()
  @IsNumber()
  @Min(5)
  intervalMinutes?: number;

  @ApiPropertyOptional({
    description: 'Days of week for weekly reminders',
    example: ['monday', 'wednesday', 'friday'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  daysOfWeek?: string[];

  @ApiPropertyOptional({
    description: 'Enable sound notification',
    example: true,
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  soundEnabled?: boolean;

  @ApiPropertyOptional({
    description: 'Enable vibration',
    example: true,
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  vibrationEnabled?: boolean;


  @ApiPropertyOptional({
    description: 'Link to nutrition plan ID if applicable',
    example: '507f1f77bcf86cd799439012',
  })
  @IsOptional()
  @IsString()
  linkedNutritionPlanId?: string;
}
