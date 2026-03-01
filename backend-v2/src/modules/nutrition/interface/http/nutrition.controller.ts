import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Roles } from '@/shared/decorators/roles.decorator';
import {
  CreateNutritionPlanUseCase,
  GetNutritionPlanByChildUseCase,
  UpdateNutritionPlanUseCase,
  DeleteNutritionPlanUseCase,
} from '../../application/use-cases/nutrition.use-cases';
import { CreateNutritionPlanDto, UpdateNutritionPlanDto } from '../../application/dto/nutrition.dto';

@ApiTags('Nutrition Plans')
@ApiBearerAuth()
@Controller('nutrition/plans')
export class NutritionController {
  constructor(
    private readonly createPlan: CreateNutritionPlanUseCase,
    private readonly getPlanByChild: GetNutritionPlanByChildUseCase,
    private readonly updatePlan: UpdateNutritionPlanUseCase,
    private readonly deletePlan: DeleteNutritionPlanUseCase,
  ) {}

  @Post()
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Create a nutrition plan for a child' })
  async create(@Body() dto: CreateNutritionPlanDto, @Req() req: any) {
    return this.createPlan.execute(dto, req.user.sub);
  }

  @Get('child/:childId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Get active nutrition plan for a child' })
  async getByChild(@Param('childId') childId: string) {
    return this.getPlanByChild.execute(childId);
  }

  @Patch(':planId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Update a nutrition plan' })
  async update(@Param('planId') planId: string, @Body() dto: UpdateNutritionPlanDto) {
    return this.updatePlan.execute(planId, dto);
  }

  @Delete(':planId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Deactivate a nutrition plan' })
  async remove(@Param('planId') planId: string) {
    return this.deletePlan.execute(planId);
  }
}
