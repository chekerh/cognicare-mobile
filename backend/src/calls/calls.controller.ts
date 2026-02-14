import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CallsService } from './calls.service';

@ApiTags('calls')
@Controller('calls')
export class CallsController {
  private readonly logger = new Logger(CallsController.name);

  constructor(private readonly callsService: CallsService) {}

  @Get('check')
  @ApiOperation({
    summary: 'Check if Agora is configured (for debugging)',
    description:
      'Returns configured status and appId length. Use to verify env vars on Render.',
  })
  checkConfig() {
    const appId = this.callsService.getAppId();
    return {
      configured: this.callsService.isConfigured(),
      appIdLength: appId.length,
      appIdValid: appId.length === 32 && /^[0-9a-fA-F]+$/.test(appId),
    };
  }

  @Get('token')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Get Agora RTC token for voice/video call',
    description:
      'Returns a token to join an Agora channel. Required for secure in-app calls.',
  })
  @ApiQuery({
    name: 'channel',
    required: true,
    description: 'Channel name (e.g. call_convId_timestamp)',
  })
  @ApiQuery({
    name: 'uid',
    required: true,
    description: 'User ID or account string for Agora',
  })
  async getToken(
    @Query('channel') channel: string,
    @Query('uid') uid: string,
    @Request() req: { user: { id: string } },
  ) {
    if (!channel || !uid) {
      throw new BadRequestException('channel and uid are required');
    }
    const token = await this.callsService.generateToken(
      channel,
      uid,
      req.user.id,
    );
    const appId = this.callsService.getAppId();
    this.logger.log(
      `token issued appIdLength=${appId.length} appIdValid=${appId.length === 32 && /^[0-9a-fA-F]+$/.test(appId)}`,
    );
    return { token, channel, uid, appId };
  }
}
