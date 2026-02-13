import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NutritionService } from './nutrition.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreateNutritionPlanDto } from './dto/create-nutrition-plan.dto';
import { UpdateNutritionPlanDto } from './dto/update-nutrition-plan.dto';

@ApiTags('nutrition')
@ApiBearerAuth()
@Controller('nutrition')
@UseGuards(JwtAuthGuard, RolesGuard)
export class NutritionController {
  constructor(private readonly nutritionService: NutritionService) {}

  @Post('plans')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Create nutrition plan for a child' })
  async createPlan(@Body() dto: CreateNutritionPlanDto, @Request() req: any) {
    return await this.nutritionService.create(dto, req.user.id as string);
  }

  @Get('plans/child/:childId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Get active nutrition plan for a child' })
  async getPlanByChildId(
    @Param('childId') childId: string,
    @Request() req: any,
  ) {
    return await this.nutritionService.findByChildId(
      childId,
      req.user.id as string,
    );
  }

  @Patch('plans/:planId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Update nutrition plan' })
  async updatePlan(
    @Param('planId') planId: string,
    @Body() dto: UpdateNutritionPlanDto,
    @Request() req: any,
  ) {
    return await this.nutritionService.update(
      planId,
      dto,
      req.user.id as string,
    );
  }

  @Delete('plans/:planId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Deactivate nutrition plan' })
  async deletePlan(@Param('planId') planId: string, @Request() req: any) {
    return await this.nutritionService.delete(planId, req.user.id as string);
  }
}
