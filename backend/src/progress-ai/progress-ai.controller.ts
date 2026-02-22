import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { AdminGuard } from '../auth/admin.guard';
import { ProgressAiService } from './progress-ai.service';
import { RecommendationFeedbackDto } from './dto/recommendation-feedback.dto';
import { UpdateSpecialistPreferencesDto } from './dto/update-preferences.dto';
import { RequestParentFeedbackDto } from './dto/request-parent-feedback.dto';
import { SubmitParentFeedbackDto } from './dto/parent-feedback.dto';

@ApiTags('Progress AI')
@Controller('progress-ai')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class ProgressAiController {
  constructor(private readonly progressAiService: ProgressAiService) {}

  @Get('child/:childId/recommendations')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'organization_leader',
  )
  @ApiOperation({ summary: 'Get AI recommendations for a child' })
  async getRecommendations(
    @Request() req: { user: { id: string; organizationId?: string; role: string } },
    @Param('childId') childId: string,
    @Query('planType') planType?: string,
    @Query('summaryLength') summaryLength?: 'short' | 'detailed',
    @Query('focusPlanTypes') focusPlanTypes?: string,
  ) {
    const preferences =
      summaryLength || focusPlanTypes
        ? {
            summaryLength: summaryLength as 'short' | 'detailed' | undefined,
            focusPlanTypes: focusPlanTypes
              ? focusPlanTypes.split(',').map((s) => s.trim())
              : undefined,
          }
        : undefined;
    return await this.progressAiService.getRecommendations(
      childId,
      req.user.organizationId,
      req.user.id,
      req.user.role,
      { planType, preferences },
    );
  }

  @Post('recommendations/:id/feedback')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Submit specialist feedback on a recommendation' })
  async submitFeedback(
    @Request() req: { user: { id: string } },
    @Param('id') recommendationId: string,
    @Body() dto: RecommendationFeedbackDto,
  ) {
    return await this.progressAiService.submitFeedback(
      recommendationId,
      {
        childId: dto.childId,
        planId: dto.planId,
        action: dto.action,
        editedText: dto.editedText,
        originalRecommendationText: dto.originalRecommendationText,
        planType: dto.planType,
        resultsImproved: dto.resultsImproved,
        parentFeedbackHelpful: dto.parentFeedbackHelpful,
      },
      req.user.id,
    );
  }

  @Get('admin/summary')
  @Roles('admin')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Admin: aggregated progress summary (no PII)' })
  async getAdminSummary() {
    return await this.progressAiService.getAdminSummary();
  }

  @Get('admin/summary-by-org')
  @Roles('admin')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Admin: aggregated progress summary per organization (no PII)' })
  async getAdminSummaryByOrg() {
    return await this.progressAiService.getAdminSummaryByOrg();
  }

  @Get('org/specialist/:specialistId/summary')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Org leader: specialist progress summary (no child PII)' })
  async getOrgSpecialistSummary(
    @Request() req: { user: { id: string } },
    @Param('specialistId') specialistId: string,
  ) {
    return await this.progressAiService.getOrgSpecialistSummary(
      specialistId,
      req.user.id,
    );
  }

  @Get('activity-suggestions')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Get 2–3 activity suggestions for specialist dashboard' })
  async getActivitySuggestions(@Request() req: { user: { id: string } }) {
    return await this.progressAiService.getActivitySuggestions(req.user.id);
  }

  @Get('preferences')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Get current specialist AI preferences' })
  async getPreferences(@Request() req: { user: { id: string } }) {
    return await this.progressAiService.getSpecialistPreferences(req.user.id);
  }

  @Patch('preferences')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
  )
  @ApiOperation({ summary: 'Update specialist AI preferences' })
  async updatePreferences(
    @Request() req: { user: { id: string } },
    @Body() dto: UpdateSpecialistPreferencesDto,
  ) {
    await this.progressAiService.updateSpecialistPreferences(req.user.id, {
      focusPlanTypes: dto.focusPlanTypes,
      summaryLength: dto.summaryLength,
      frequency: dto.frequency,
      planTypeWeights: dto.planTypeWeights,
    });
    return await this.progressAiService.getSpecialistPreferences(req.user.id);
  }

  @Get('child/:childId/parent-summary')
  @Roles('family')
  @ApiOperation({ summary: 'Get AI summary for parent (week or month)' })
  @ApiQuery({ name: 'period', required: true, enum: ['week', 'month'] })
  async getParentSummary(
    @Request() req: { user: { id: string } },
    @Param('childId') childId: string,
    @Query('period') period: string,
  ) {
    const p = period === 'month' ? 'month' : 'week';
    return await this.progressAiService.getParentSummary(
      childId,
      req.user.id,
      p,
    );
  }

  @Post('child/:childId/request-parent-feedback')
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'organization_leader',
  )
  @ApiOperation({ summary: 'Request parent feedback for a child (after AI suggestion)' })
  async requestParentFeedback(
    @Request() req: { user: { id: string; role: string } },
    @Param('childId') childId: string,
    @Body() dto: RequestParentFeedbackDto,
  ) {
    return await this.progressAiService.requestParentFeedback(
      childId,
      req.user.id,
      req.user.role,
      {
        recommendationId: dto.recommendationId,
        message: dto.message,
        planType: dto.planType,
      },
    );
  }

  @Post('child/:childId/parent-feedback')
  @Roles('family')
  @ApiOperation({ summary: 'Submit parent feedback (rating + comment) for a child' })
  async submitParentFeedback(
    @Request() req: { user: { id: string } },
    @Param('childId') childId: string,
    @Body() dto: SubmitParentFeedbackDto,
  ) {
    return await this.progressAiService.submitParentFeedback(
      childId,
      req.user.id,
      {
        rating: dto.rating,
        comment: dto.comment,
        planType: dto.planType,
      },
    );
  }

  @Get('child/:childId/parent-feedback')
  @Roles('family')
  @ApiOperation({ summary: 'Get recent parent feedback entries for a child' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Maximum number of entries (default: 10)' })
  async getParentFeedback(
    @Request() req: { user: { id: string } },
    @Param('childId') childId: string,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return await this.progressAiService.getParentFeedback(
      childId,
      req.user.id,
      limitNum,
    );
  }
}
