import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
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
    const userId = req.user.id as string;
    return this.conversationsService.findInboxForUser(userId);
  }

  @Get('by-participant/:otherUserId')
  @ApiOperation({ summary: 'Get or create conversation with another user' })
  async getOrCreateConversation(
    @Request() req: any,
    @Param('otherUserId') otherUserId: string,
  ) {
    const userId = req.user.id as string;
    const role = (req.user.role as string)?.toLowerCase?.();
    return this.conversationsService.getOrCreateConversation(
      userId,
      otherUserId,
      role,
    );
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Get messages for a conversation' })
  async getMessages(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.id as string;
    return this.conversationsService.getMessages(id, userId);
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in a conversation' })
  async sendMessage(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { text: string },
  ) {
    const userId = req.user.id as string;
    if (!body?.text || typeof body.text !== 'string' || !body.text.trim()) {
      throw new BadRequestException('text is required');
    }
    return this.conversationsService.addMessage(id, userId, body.text.trim());
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a conversation (both sides)' })
  async deleteConversation(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.id as string;
    await this.conversationsService.deleteConversation(id, userId);
    return { success: true };
  }
}
