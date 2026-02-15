import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
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

  @Post('groups')
  @ApiOperation({ summary: 'Create a group conversation (e.g. family group)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Group name' },
        participantIds: {
          type: 'array',
          items: { type: 'string' },
          description: 'User IDs to add (creator is added automatically)',
        },
      },
      required: ['name', 'participantIds'],
    },
  })
  async createGroup(
    @Request() req: any,
    @Body() body: { name: string; participantIds: string[] },
  ) {
    const userId = req.user.id as string;
    const name = typeof body?.name === 'string' ? body.name.trim() : 'Groupe';
    const participantIds = Array.isArray(body?.participantIds)
      ? body.participantIds.filter((id) => typeof id === 'string')
      : [];
    return this.conversationsService.createGroup(userId, name, participantIds);
  }

  @Post(':id/members')
  @ApiOperation({ summary: 'Add a member to a group conversation' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { userId: { type: 'string' } },
      required: ['userId'],
    },
  })
  async addMemberToGroup(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { userId: string },
  ) {
    const currentUserId = req.user.id as string;
    const newParticipantId = body?.userId;
    if (!newParticipantId || typeof newParticipantId !== 'string') {
      throw new BadRequestException('userId is required');
    }
    return this.conversationsService.addMemberToGroup(
      id,
      currentUserId,
      newParticipantId,
    );
  }

  @Get(':id/settings')
  @ApiOperation({ summary: 'Get conversation settings (autoSavePhotos, muted)' })
  async getSettings(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.id as string;
    return this.conversationsService.getSettings(id, userId);
  }

  @Patch(':id/settings')
  @ApiOperation({ summary: 'Update conversation settings' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        autoSavePhotos: { type: 'boolean' },
        muted: { type: 'boolean' },
      },
    },
  })
  async updateSettings(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { autoSavePhotos?: boolean; muted?: boolean },
  ) {
    const userId = req.user.id as string;
    return this.conversationsService.updateSettings(id, userId, body);
  }

  @Get(':id/media')
  @ApiOperation({ summary: 'Get media (images, voice) in conversation' })
  async getMedia(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.id as string;
    return this.conversationsService.getMedia(id, userId);
  }

  @Get(':id/search')
  @ApiOperation({ summary: 'Search messages in conversation' })
  async searchMessages(
    @Request() req: any,
    @Param('id') id: string,
    @Query('q') q: string,
  ) {
    const userId = req.user.id as string;
    return this.conversationsService.searchMessages(id, userId, q ?? '');
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
