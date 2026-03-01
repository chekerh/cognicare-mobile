import {
  IsNotEmpty, IsOptional, IsString, IsNumber, IsArray,
  IsBoolean, IsEnum, IsDateString, ValidateNested, Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ReminderType, ReminderFrequency } from '../../domain';

class MedicationDto {
  @ApiProperty() @IsString() name!: string;
  @ApiProperty() @IsString() dosage!: string;
  @ApiProperty() @IsString() time!: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() withFood?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsString() notes?: string;
}

class SnackDto {
  @ApiProperty() @IsString() time!: string;
  @ApiProperty() @IsArray() @IsString({ each: true }) items!: string[];
}

export class CreateNutritionPlanDto {
  @ApiProperty() @IsNotEmpty() @IsString() childId!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(1) dailyWaterGoal?: number;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(30) waterReminderInterval?: number;
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) breakfast?: string[];
  @ApiPropertyOptional() @IsOptional() @IsString() breakfastTime?: string;
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) lunch?: string[];
  @ApiPropertyOptional() @IsOptional() @IsString() lunchTime?: string;
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) dinner?: string[];
  @ApiPropertyOptional() @IsOptional() @IsString() dinnerTime?: string;
  @ApiPropertyOptional() @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => SnackDto) snacks?: SnackDto[];
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) allergies?: string[];
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) restrictions?: string[];
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) preferences?: string[];
  @ApiPropertyOptional() @IsOptional() @IsArray() @ValidateNested({ each: true }) @Type(() => MedicationDto) medications?: MedicationDto[];
  @ApiPropertyOptional() @IsOptional() @IsString() specialNotes?: string;
}

export class UpdateNutritionPlanDto extends CreateNutritionPlanDto {
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
  @ApiPropertyOptional() @IsOptional() override childId!: string;
}

export class CreateTaskReminderDto {
  @ApiProperty() @IsNotEmpty() @IsString() childId!: string;
  @ApiProperty({ enum: ReminderType }) @IsEnum(ReminderType) type!: ReminderType;
  @ApiProperty() @IsNotEmpty() @IsString() title!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() icon?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() color?: string;
  @ApiProperty({ enum: ReminderFrequency }) @IsEnum(ReminderFrequency) frequency!: ReminderFrequency;
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) times?: string[];
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(5) intervalMinutes?: number;
  @ApiPropertyOptional() @IsOptional() @IsArray() @IsString({ each: true }) daysOfWeek?: string[];
  @ApiPropertyOptional() @IsOptional() @IsBoolean() soundEnabled?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() vibrationEnabled?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsString() linkedNutritionPlanId?: string;
}

export class UpdateTaskReminderDto extends CreateTaskReminderDto {
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
  @ApiPropertyOptional() @IsOptional() override childId!: string;
  @ApiPropertyOptional() @IsOptional() override type!: ReminderType;
  @ApiPropertyOptional() @IsOptional() override title!: string;
  @ApiPropertyOptional() @IsOptional() override frequency!: ReminderFrequency;
}

export class CompleteTaskDto {
  @ApiProperty() @IsNotEmpty() @IsString() reminderId!: string;
  @ApiProperty() @IsNotEmpty() @IsBoolean() completed!: boolean;
  @ApiProperty() @IsNotEmpty() @IsDateString() date!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() feedback?: string;
}
