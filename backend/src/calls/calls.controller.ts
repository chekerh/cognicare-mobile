import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('calls')
@Controller('calls')
export class CallsController {
  @Get('check')
  @ApiOperation({
    summary: 'Call config check',
    description:
      'App uses WebRTC for peer-to-peer voice/video; signaling is via WebSocket (Socket.IO).',
  })
  checkConfig() {
    return { provider: 'webrtc', signaling: 'websocket' };
  }
}
