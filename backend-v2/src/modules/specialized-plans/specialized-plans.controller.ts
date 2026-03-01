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
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { JwtAuthGuard } from "@/shared/guards/jwt-auth.guard";
import { Roles } from "@/shared/decorators/roles.decorator";
import { SpecializedPlansService } from "./specialized-plans.service";
import { CreatePlanDto } from "./dto/create-plan.dto";

const SPECIALIST_ROLES = [
  "psychologist",
  "speech_therapist",
  "occupational_therapist",
  "doctor",
  "volunteer",
] as const;

@ApiTags("Specialized Plans (PECS/TEACCH)")
@Controller("specialized-plans")
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SpecializedPlansController {
  constructor(private readonly plansService: SpecializedPlansService) {}

  @Post("upload-image")
  @Roles(...SPECIALIST_ROLES)
  @UseInterceptors(FileInterceptor("file"))
  @ApiOperation({ summary: "Upload image for PECS card" })
  async uploadImage(
    @UploadedFile() file?: { buffer: Buffer; mimetype: string },
  ) {
    if (!file?.buffer) throw new BadRequestException("No file provided");
    const imageUrl = await this.plansService.uploadImage(file);
    return { imageUrl };
  }

  @Post()
  @Roles(...SPECIALIST_ROLES)
  @ApiOperation({ summary: "Create a new PECS or TEACCH plan for a child" })
  async createPlan(@Request() req: any, @Body() data: CreatePlanDto) {
    return await this.plansService.createPlan(
      req.user.userId,
      req.user.organizationId,
      data,
    );
  }

  @Get("child/:childId")
  @Roles(...SPECIALIST_ROLES, "organization_leader")
  @ApiOperation({ summary: "Get all active plans for a specific child" })
  async getByChild(@Request() req: any, @Param("childId") childId: string) {
    return await this.plansService.getPlansByChild(
      childId,
      req.user.organizationId,
    );
  }

  @Get("child/:childId/progress-summary")
  @Roles("family")
  @ApiOperation({ summary: "Get progress summary for a child (parent only)" })
  async getProgressSummary(
    @Request() req: any,
    @Param("childId") childId: string,
  ) {
    return await this.plansService.getProgressSummaryForParent(
      childId,
      req.user.userId,
    );
  }

  @Get("my-plans")
  @Roles(...SPECIALIST_ROLES)
  @ApiOperation({ summary: "Get plans created by the current specialist" })
  async getMyPlans(@Request() req: any) {
    return await this.plansService.getPlansBySpecialist(req.user.userId);
  }

  @Patch(":id")
  @Roles(...SPECIALIST_ROLES)
  @ApiOperation({ summary: "Update plan content" })
  async updatePlan(
    @Request() req: any,
    @Param("id") id: string,
    @Body("content") content: any,
  ) {
    return await this.plansService.updatePlan(id, req.user.userId, content);
  }

  @Delete(":id")
  @Roles(...SPECIALIST_ROLES)
  @ApiOperation({ summary: "Delete a plan" })
  async deletePlan(@Request() req: any, @Param("id") id: string) {
    return await this.plansService.deletePlan(id, req.user.userId);
  }
}
