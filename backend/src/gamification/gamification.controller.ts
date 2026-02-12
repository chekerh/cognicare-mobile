import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GamificationService } from './gamification.service';
import { RecordGameSessionDto } from './dto/record-game-session.dto';

@ApiTags('gamification')
@Controller('gamification')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GamificationController {
  private readonly logger = new Logger(GamificationController.name);

  constructor(private readonly gamificationService: GamificationService) {}

  @Post('children/:childId/game-session')
  @ApiOperation({ summary: 'Record a game session and update points/badges' })
  async recordGameSession(
    @Param('childId') childId: string,
    @Body() dto: RecordGameSessionDto,
  ) {
    // Verify child belongs to user's family
    // TODO: Add authorization check
    const result = await this.gamificationService.recordGameSession(
      childId,
      dto,
    );
    return result;
  }

  @Get('children/:childId/stats')
  @ApiOperation({
    summary: 'Get child gamification stats (points, badges, progress)',
  })
  async getChildStats(@Param('childId') childId: string) {
    // TODO: Add authorization check
    return this.gamificationService.getChildStats(childId);
  }
}
