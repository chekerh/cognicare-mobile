import { PartialType } from '@nestjs/swagger';
import { CreateNutritionPlanDto } from './create-nutrition-plan.dto';
import { IsOptional, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateNutritionPlanDto extends PartialType(
  CreateNutritionPlanDto,
) {
  @ApiPropertyOptional({
    description: 'Whether this nutrition plan is active',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
