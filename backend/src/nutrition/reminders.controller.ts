import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Request,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
  ApiConsumes,
} from '@nestjs/swagger';
import { RemindersService } from './reminders.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreateTaskReminderDto } from './dto/create-task-reminder.dto';
import { UpdateTaskReminderDto } from './dto/update-task-reminder.dto';
import { CompleteTaskDto } from './dto/complete-task.dto';

@ApiTags('reminders')
@ApiBearerAuth()
@Controller('reminders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  @Post()
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Create a task reminder for a child' })
  async createReminder(
    @Body() dto: CreateTaskReminderDto,
    @Request() req: any,
  ) {
    return await this.remindersService.create(dto, req.user.id as string);
  }

  @Get('child/:childId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Get all active reminders for a child' })
  async getRemindersByChildId(
    @Param('childId') childId: string,
    @Request() req: any,
  ) {
    return await this.remindersService.findByChildId(
      childId,
      req.user.id as string,
    );
  }

  @Get('child/:childId/today')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: "Get today's reminders for a child" })
  async getTodayReminders(
    @Param('childId') childId: string,
    @Request() req: any,
  ) {
    return await this.remindersService.getTodayReminders(
      childId,
      req.user.id as string,
    );
  }

  @Patch(':reminderId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Update a task reminder' })
  async updateReminder(
    @Param('reminderId') reminderId: string,
    @Body() dto: UpdateTaskReminderDto,
    @Request() req: any,
  ) {
    return await this.remindersService.update(
      reminderId,
      dto,
      req.user.id as string,
    );
  }

  @Post('complete')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @UseInterceptors(FileInterceptor('proofImage'))
  @ApiOperation({
    summary:
      'Mark a task as completed or incomplete, optionally with proof image',
  })
  @ApiConsumes('multipart/form-data')
  async completeTask(
    @Body() dto: CompleteTaskDto,
    @UploadedFile() proofImage: { buffer: Buffer; originalname: string } | undefined,
    @Request() req: any,
  ) {
    return await this.remindersService.completeTask(
      dto,
      req.user.id as string,
      proofImage,
    );
  }

  @Delete(':reminderId')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Deactivate a reminder' })
  async deleteReminder(
    @Param('reminderId') reminderId: string,
    @Request() req: any,
  ) {
    return await this.remindersService.delete(
      reminderId,
      req.user.id as string,
    );
  }

  @Get('child/:childId/stats')
  @Roles(
    'family',
    'doctor',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
  )
  @ApiOperation({ summary: 'Get completion statistics for a child' })
  @ApiQuery({
    name: 'days',
    required: false,
    type: Number,
    description: 'Number of days to include (default: 7)',
  })
  async getStats(
    @Param('childId') childId: string,
    @Query('days') days: string,
    @Request() req: any,
  ) {
    const numDays = days ? parseInt(days, 10) : 7;
    return await this.remindersService.getCompletionStats(
      childId,
      req.user.id as string,
      numDays,
    );
  }
}
