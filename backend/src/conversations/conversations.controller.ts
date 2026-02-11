import { Controller, Get, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ConversationsService } from './conversations.service';

@ApiTags('conversations')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Get('inbox')
  @ApiOperation({ summary: 'Get inbox conversations for current user' })
  async getInbox(@Request() req: any) {
    const userId = req.user.userId as string;
    return this.conversationsService.findInboxForUser(userId);
  }
}

