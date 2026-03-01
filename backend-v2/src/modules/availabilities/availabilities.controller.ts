import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { JwtAuthGuard } from "@/shared/guards/jwt-auth.guard";
import { Public } from "@/shared/decorators/public.decorator";
import { AvailabilitiesService } from "./availabilities.service";

@ApiTags("availabilities")
@Controller("availabilities")
export class AvailabilitiesController {
  constructor(private readonly availabilitiesService: AvailabilitiesService) {}

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Publish availability (volunteer)" })
  async create(@Req() req: any, @Body() body: any) {
    const userId = req.user.userId as string;
    const role = (req.user.role as string)?.toLowerCase?.();
    if (role !== "volunteer")
      throw new ForbiddenException("Only volunteers can publish availability");
    const dates = Array.isArray(body.dates) ? body.dates : [];
    if (dates.length === 0)
      throw new BadRequestException("At least one date is required");
    return this.availabilitiesService.create(userId, {
      dates,
      startTime: body.startTime,
      endTime: body.endTime,
      recurrence: body.recurrence,
      recurrenceOn: body.recurrenceOn,
    });
  }

  @Get("for-families")
  @Public()
  @ApiOperation({ summary: "List availabilities for family home" })
  async listForFamilies() {
    return this.availabilitiesService.listForFamilies();
  }
}
