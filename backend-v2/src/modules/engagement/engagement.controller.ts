import { Controller, Get, Query, UseGuards, Req } from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from "@nestjs/swagger";
import { JwtAuthGuard } from "@/shared/guards/jwt-auth.guard";
import {
  EngagementService,
  EngagementDashboardDto,
} from "./engagement.service";

@ApiTags("engagement")
@Controller("engagement")
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class EngagementController {
  constructor(private readonly engagementService: EngagementService) {}

  @Get("dashboard")
  @ApiOperation({
    summary: "Get engagement dashboard (play time, activities, badges)",
  })
  @ApiQuery({ name: "childId", required: false })
  async getDashboard(
    @Req() req: any,
    @Query("childId") childId?: string,
  ): Promise<EngagementDashboardDto> {
    return this.engagementService.getDashboard(req.user.userId, childId);
  }
}
