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
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
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

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        type: { type: 'string', enum: ['image', 'voice'] },
      },
      required: ['file', 'type'],
    },
  })
  @ApiOperation({ summary: 'Upload chat attachment (image or voice)' })
  async uploadAttachment(
    @Request() req: any,
    @UploadedFile() file: { buffer: Buffer; mimetype: string },
    @Body() body: { type: string },
  ) {
    const userId = req.user.id as string;
    const type = (body?.type ?? '').toLowerCase();
    if (type !== 'image' && type !== 'voice') {
      throw new BadRequestException('type must be image or voice');
    }
    if (!file?.buffer) {
      throw new BadRequestException('No file provided');
    }
    const url = await this.conversationsService.uploadAttachment(
      userId,
      { buffer: file.buffer, mimetype: file.mimetype ?? '' },
      type,
    );
    return { url };
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in a conversation' })
  async sendMessage(
    @Request() req: any,
    @Param('id') id: string,
    @Body()
    body: {
      text: string;
      attachmentUrl?: string;
      attachmentType?: 'image' | 'voice' | 'call_missed';
    },
  ) {
    const userId = req.user.id as string;
    const text = typeof body?.text === 'string' ? body.text.trim() : '';
    if (!text && !body?.attachmentUrl) {
      throw new BadRequestException('text or attachmentUrl is required');
    }
    const fallbackText = body?.attachmentType === 'call_missed'
      ? 'Appel manqué'
      : body?.attachmentType === 'voice'
        ? 'Message vocal'
        : 'Photo';
    return this.conversationsService.addMessage(
      id,
      userId,
      text || fallbackText,
      body.attachmentUrl,
      body.attachmentType,
    );
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a conversation (both sides)' })
  async deleteConversation(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.id as string;
    await this.conversationsService.deleteConversation(id, userId);
    return { success: true };
  }
}
