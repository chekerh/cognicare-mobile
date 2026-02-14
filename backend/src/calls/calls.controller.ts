import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CallsService } from './calls.service';

@ApiTags('calls')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('calls')
export class CallsController {
  constructor(private readonly callsService: CallsService) {}

  @Get('token')
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
    return { token, channel, uid, appId: this.callsService.getAppId() };
  }
}
