import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SpecializedPlansService } from './specialized-plans.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreatePlanDto } from './dto/create-plan.dto';

@ApiTags('Specialized Plans (PECS/TEACCH)')
@Controller('specialized-plans')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class SpecializedPlansController {
  constructor(private readonly plansService: SpecializedPlansService) {}

  @Post('upload-image')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload image for PECS card' })
  async uploadImage(
    @UploadedFile()
    file?: { buffer: Buffer; mimetype: string },
  ) {
    if (!file?.buffer) throw new BadRequestException('No file provided');
    const imageUrl = await this.plansService.uploadImage(file);
    return { imageUrl };
  }

  @Post()
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Create a new PECS or TEACCH plan for a child' })
  async createPlan(
    @Request() req: { user: { id: string; organizationId: string } },
    @Body() data: CreatePlanDto,
  ) {
    return await this.plansService.createPlan(
      req.user.id,
      req.user.organizationId,
      data,
    );
  }

  @Get('child/:childId')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'organization_leader',
  )
  @ApiOperation({ summary: 'Get all active plans for a specific child' })
  async getByChild(
    @Request() req: { user: { organizationId?: string } },
    @Param('childId') childId: string,
  ) {
    return await this.plansService.getPlansByChild(
      childId,
      req.user.organizationId,
    );
  }

  @Get('child/:childId/progress-summary')
  @Roles('family')
  @ApiOperation({ summary: 'Get progress summary for a child (parent only, no plan content)' })
  async getProgressSummary(
    @Request() req: { user: { id: string } },
    @Param('childId') childId: string,
  ) {
    return await this.plansService.getProgressSummaryForParent(
      childId,
      req.user.id,
    );
  }

  @Get('my-plans')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Get plans created by the current specialist' })
  async getMyPlans(@Request() req: { user: { id: string } }) {
    return await this.plansService.getPlansBySpecialist(req.user.id);
  }

  @Patch(':id')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Update plan content' })
  async updatePlan(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
    @Body('content') content: any,
  ) {
    return await this.plansService.updatePlan(id, req.user.id, content);
  }

  @Delete(':id')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Delete a plan' })
  async deletePlan(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    return await this.plansService.deletePlan(id, req.user.id);
  }
}
