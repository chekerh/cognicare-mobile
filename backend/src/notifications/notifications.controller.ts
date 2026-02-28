import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { CreateNotificationDto } from './dto/create-notification.dto';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'List notifications for the current user' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'List of notifications' })
  async list(
    @Request() req: { user: { id: string } },
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit
      ? Math.min(100, Math.max(1, parseInt(limit, 10) || 50))
      : 50;

    // Sync routine reminders with persistent feed
    await this.notifications.syncRoutineReminders(req.user.id);

    const list = await this.notifications.listForUser(req.user.id, limitNum);
    const unreadCount = await this.notifications.countUnread(req.user.id);
    return { notifications: list, unreadCount };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark one notification as read' })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({ status: 200, description: 'OK' })
  async markRead(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    await this.notifications.markRead(req.user.id, id);
    return { ok: true };
  }

  @Post('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200, description: 'OK' })
  async markAllRead(@Request() req: { user: { id: string } }) {
    await this.notifications.markAllRead(req.user.id);
    return { ok: true };
  }

  @Post()
  @ApiOperation({
    summary: 'Create a notification (for current user or from other services)',
  })
  @ApiResponse({ status: 201, description: 'Notification created' })
  async create(
    @Request() req: { user: { id: string } },
    @Body() dto: CreateNotificationDto,
  ) {
    const notification = await this.notifications.createForUser(req.user.id, {
      type: dto.type,
      title: dto.title,
      description: dto.description,
      data: dto.data,
    });
    return {
      id: notification._id.toString(),
      type: notification.type,
      title: notification.title,
      description: notification.description,
      read: notification.read,
      createdAt: notification.createdAt,
    };
  }
}
