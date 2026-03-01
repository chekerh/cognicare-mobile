import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiConsumes } from '@nestjs/swagger';
import { Roles } from '@/shared/decorators/roles.decorator';
import {
  CreateTaskReminderUseCase,
  GetRemindersByChildUseCase,
  GetTodayRemindersUseCase,
  UpdateTaskReminderUseCase,
  CompleteTaskUseCase,
  DeleteTaskReminderUseCase,
  GetCompletionStatsUseCase,
} from '../../application/use-cases/nutrition.use-cases';
import { CreateTaskReminderDto, UpdateTaskReminderDto, CompleteTaskDto } from '../../application/dto/nutrition.dto';

@ApiTags('Task Reminders')
@ApiBearerAuth()
@Controller('reminders')
export class RemindersController {
  constructor(
    private readonly createReminder: CreateTaskReminderUseCase,
    private readonly getRemindersByChild: GetRemindersByChildUseCase,
    private readonly getTodayReminders: GetTodayRemindersUseCase,
    private readonly updateReminder: UpdateTaskReminderUseCase,
    private readonly completeTask: CompleteTaskUseCase,
    private readonly deleteReminder: DeleteTaskReminderUseCase,
    private readonly getStats: GetCompletionStatsUseCase,
  ) {}

  @Post()
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Create a task reminder' })
  async create(@Body() dto: CreateTaskReminderDto, @Req() req: any) {
    return this.createReminder.execute(dto, req.user.sub);
  }

  @Get('child/:childId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Get all active reminders for a child' })
  async getByChild(@Param('childId') childId: string) {
    return this.getRemindersByChild.execute(childId);
  }

  @Get('child/:childId/today')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: "Get today's reminders for a child" })
  async getToday(@Param('childId') childId: string) {
    return this.getTodayReminders.execute(childId);
  }

  @Patch(':reminderId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Update a task reminder' })
  async update(@Param('reminderId') reminderId: string, @Body() dto: UpdateTaskReminderDto) {
    return this.updateReminder.execute(reminderId, dto);
  }

  @Post('complete')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @UseInterceptors(FileInterceptor('proofImage'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Complete/uncomplete a task with optional proof image' })
  async complete(
    @Body() dto: CompleteTaskDto,
    @Req() req: any,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.completeTask.execute(dto, req.user.sub, file);
  }

  @Delete(':reminderId')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Deactivate a task reminder' })
  async remove(@Param('reminderId') reminderId: string) {
    return this.deleteReminder.execute(reminderId);
  }

  @Get('child/:childId/stats')
  @Roles('family', 'doctor', 'psychologist', 'speech_therapist', 'occupational_therapist')
  @ApiOperation({ summary: 'Get completion statistics for a child' })
  async completionStats(@Param('childId') childId: string, @Query('days') days?: string) {
    return this.getStats.execute(childId, days ? parseInt(days, 10) : 7);
  }
}
