import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { RecordGameSessionDto } from '../../application/dto/gamification.dto';
import { RecordGameSessionUseCase, GetChildStatsUseCase } from '../../application/use-cases/gamification.use-cases';

@ApiTags('gamification')
@ApiBearerAuth('JWT-auth')
@Controller('gamification')
export class GamificationController {
  constructor(
    private readonly recordSessionUC: RecordGameSessionUseCase,
    private readonly getStatsUC: GetChildStatsUseCase,
  ) {}

  @Post('children/:childId/game-session')
  @ApiOperation({ summary: 'Record a game session and update points/badges' })
  async recordGameSession(@Param('childId') childId: string, @Body() dto: RecordGameSessionDto) {
    const result = await this.recordSessionUC.execute(childId, dto);
    return result.value;
  }

  @Get('children/:childId/stats')
  @ApiOperation({ summary: 'Get child gamification stats' })
  async getChildStats(@Param('childId') childId: string) {
    const result = await this.getStatsUC.execute(childId);
    return result.value;
  }
}
