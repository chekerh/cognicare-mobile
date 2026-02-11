import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AvailabilitiesService } from './availabilities.service';

@ApiTags('availabilities')
@Controller('availabilities')
export class AvailabilitiesController {
  constructor(private readonly availabilitiesService: AvailabilitiesService) {}

  @Post()
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Publish availability (volunteer)' })
  async create(@Request() req: any, @Body() body: any) {
    const userId = req.user.id as string;
    const role = (req.user.role as string)?.toLowerCase?.();
    if (role !== 'volunteer') {
      throw new ForbiddenException('Only volunteers can publish availability');
    }
    const dates = Array.isArray(body.dates) ? body.dates : [];
    if (dates.length === 0) {
      throw new BadRequestException('At least one date is required');
    }
    return this.availabilitiesService.create(userId, {
      dates,
      startTime: body.startTime,
      endTime: body.endTime,
      recurrence: body.recurrence,
      recurrenceOn: body.recurrenceOn,
    });
  }

  @Get('for-families')
  @ApiOperation({
    summary: 'List availabilities for family home (public or auth)',
  })
  async listForFamilies() {
    return this.availabilitiesService.listForFamilies();
  }
}
