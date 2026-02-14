import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { EngagementService, EngagementDashboardDto } from './engagement.service';

@ApiTags('engagement')
@Controller('engagement')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class EngagementController {
  constructor(private readonly engagementService: EngagementService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get engagement dashboard (play time, activities, badges)' })
  @ApiQuery({ name: 'childId', required: false, description: 'Child ID; if omitted, first child of the family is used' })
  async getDashboard(
    @Request() req: { user: { id: string } },
    @Query('childId') childId?: string,
  ): Promise<EngagementDashboardDto> {
    return this.engagementService.getDashboard(req.user.id, childId);
  }
}
