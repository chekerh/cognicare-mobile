import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsArray,
  IsBoolean,
  ValidateNested,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

class MedicationDto {
  @ApiProperty({ example: 'Melatonin' })
  @IsNotEmpty()
  @IsString()
  name!: string;

  @ApiProperty({ example: '1mg' })
  @IsNotEmpty()
  @IsString()
  dosage!: string;

  @ApiProperty({ example: '20:00' })
  @IsNotEmpty()
  @IsString()
  time!: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  withFood?: boolean;

  @ApiPropertyOptional({ example: 'Take with glass of water' })
  @IsOptional()
  @IsString()
  notes?: string;
}

class SnackDto {
  @ApiProperty({ example: '10:00' })
  @IsNotEmpty()
  @IsString()
  time!: string;

  @ApiProperty({ example: ['Apple slices', 'Crackers'] })
  @IsArray()
  @IsString({ each: true })
  items!: string[];
}

export class CreateNutritionPlanDto {
  @ApiProperty({
    description: 'Child ID for this nutrition plan',
    example: '507f1f77bcf86cd799439011',
  })
  @IsNotEmpty()
  @IsString()
  childId!: string;

  @ApiPropertyOptional({
    description: 'Daily water intake goal (number of glasses)',
    example: 6,
    default: 6,
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  dailyWaterGoal?: number;

  @ApiPropertyOptional({
    description: 'Water reminder interval in minutes',
    example: 120,
    default: 120,
  })
  @IsOptional()
  @IsNumber()
  @Min(30)
  waterReminderInterval?: number;

  @ApiPropertyOptional({
    description: 'Breakfast items',
    example: ['Oatmeal', 'Banana', 'Milk'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  breakfast?: string[];

  @ApiPropertyOptional({ description: 'Breakfast time', example: '08:00' })
  @IsOptional()
  @IsString()
  breakfastTime?: string;

  @ApiPropertyOptional({
    description: 'Lunch items',
    example: ['Chicken', 'Rice', 'Vegetables'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  lunch?: string[];

  @ApiPropertyOptional({ description: 'Lunch time', example: '12:30' })
  @IsOptional()
  @IsString()
  lunchTime?: string;

  @ApiPropertyOptional({
    description: 'Dinner items',
    example: ['Fish', 'Pasta', 'Salad'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dinner?: string[];

  @ApiPropertyOptional({ description: 'Dinner time', example: '18:00' })
  @IsOptional()
  @IsString()
  dinnerTime?: string;

  @ApiPropertyOptional({
    description: 'Snacks with times',
    type: [SnackDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SnackDto)
  snacks?: SnackDto[];

  @ApiPropertyOptional({
    description: 'Food allergies',
    example: ['Peanuts', 'Dairy'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allergies?: string[];

  @ApiPropertyOptional({
    description: 'Dietary restrictions',
    example: ['Gluten-free', 'Low sugar'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  restrictions?: string[];

  @ApiPropertyOptional({
    description: 'Food preferences',
    example: ['Vegetarian', 'Likes fruits'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  preferences?: string[];

  @ApiPropertyOptional({
    description: 'Medications and supplements',
    type: [MedicationDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MedicationDto)
  medications?: MedicationDto[];

  @ApiPropertyOptional({
    description: 'Special notes about nutrition',
    example: 'Prefers small frequent meals',
  })
  @IsOptional()
  @IsString()
  specialNotes?: string;
}
