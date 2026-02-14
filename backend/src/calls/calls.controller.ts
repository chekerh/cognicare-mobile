import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('calls')
@Controller('calls')
export class CallsController {
  @Get('check')
  @ApiOperation({
    summary: 'Call config check',
    description:
      'App uses Jitsi Meet for voice/video; signaling is via WebSocket.',
  })
  checkConfig() {
    return { provider: 'jitsi', signaling: 'websocket' };
  }
}
