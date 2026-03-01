import {
  Controller, Get, Post, Patch, Body, Param, Query, Request, NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { CreateNotificationDto } from '../../application/dto/notification.dto';
import {
  ListNotificationsUseCase, CountUnreadUseCase, MarkReadUseCase,
  MarkAllReadUseCase, CreateNotificationUseCase, SyncRoutineRemindersUseCase,
} from '../../application/use-cases/notification.use-cases';

@ApiTags('notifications')
@ApiBearerAuth('JWT-auth')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly listUC: ListNotificationsUseCase,
    private readonly countUnreadUC: CountUnreadUseCase,
    private readonly markReadUC: MarkReadUseCase,
    private readonly markAllReadUC: MarkAllReadUseCase,
    private readonly createUC: CreateNotificationUseCase,
    private readonly syncUC: SyncRoutineRemindersUseCase,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List notifications for the current user' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async list(@Request() req: { user: { id: string } }, @Query('limit') limit?: string) {
    const limitNum = limit ? Math.min(100, Math.max(1, parseInt(limit, 10) || 50)) : 50;
    await this.syncUC.execute(req.user.id);
    const listResult = await this.listUC.execute(req.user.id, limitNum);
    const countResult = await this.countUnreadUC.execute(req.user.id);
    return { notifications: listResult.value, unreadCount: countResult.value };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark one notification as read' })
  async markRead(@Request() req: { user: { id: string } }, @Param('id') id: string) {
    const result = await this.markReadUC.execute(req.user.id, id);
    if (result.isFailure) throw new NotFoundException(result.error);
    return { ok: true };
  }

  @Post('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllRead(@Request() req: { user: { id: string } }) {
    await this.markAllReadUC.execute(req.user.id);
    return { ok: true };
  }

  @Post()
  @ApiOperation({ summary: 'Create a notification' })
  async create(@Request() req: { user: { id: string } }, @Body() dto: CreateNotificationDto) {
    const result = await this.createUC.execute(req.user.id, {
      type: dto.type, title: dto.title, description: dto.description, data: dto.data,
    });
    return result.value;
  }
}
