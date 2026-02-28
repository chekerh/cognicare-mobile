import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as fs from 'fs';
import * as path from 'path';
import {
  TaskReminder,
  TaskReminderDocument,
  ReminderFrequency,
} from './schemas/task-reminder.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateTaskReminderDto } from './dto/create-task-reminder.dto';
import { UpdateTaskReminderDto } from './dto/update-task-reminder.dto';
import { CompleteTaskDto } from './dto/complete-task.dto';
import { MedicationVerificationService } from '../health/medication-verification.service';
import { ReminderType } from './schemas/task-reminder.schema';

@Injectable()
export class RemindersService {
  private readonly logger = new Logger(RemindersService.name);
  constructor(
    @InjectModel(TaskReminder.name)
    private taskReminderModel: Model<TaskReminderDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private medicationVerificationService: MedicationVerificationService,
  ) {}

  /**
   * Create a task reminder for a child
   */
  async create(dto: CreateTaskReminderDto, userId: string) {
    // Verify child exists
    const child = await this.childModel.findById(dto.childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    // Verify authorization
    await this.verifyAccess(dto.childId, userId);

    // Create reminder
    const reminder = new this.taskReminderModel({
      ...dto,
      childId: new Types.ObjectId(dto.childId),
      createdBy: new Types.ObjectId(userId),
      linkedNutritionPlanId: dto.linkedNutritionPlanId
        ? new Types.ObjectId(dto.linkedNutritionPlanId)
        : undefined,
    });

    await reminder.save();

    return this.formatReminder(reminder);
  }

  /**
   * Get all active reminders for a child
   */
  async findByChildId(childId: string, userId: string) {
    const child = await this.childModel.findById(childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    // Verify authorization
    await this.verifyAccess(childId, userId);

    const reminders = await this.taskReminderModel
      .find({ childId: new Types.ObjectId(childId), isActive: true })
      .sort({ createdAt: -1 })
      .exec();

    return reminders.map((r) => this.formatReminder(r));
  }

  /**
   * Get reminders for today for a child
   */
  async getTodayReminders(childId: string, userId: string) {
    const child = await this.childModel.findById(childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    // Verify authorization
    await this.verifyAccess(childId, userId);

    const reminders = await this.taskReminderModel
      .find({ childId: new Types.ObjectId(childId), isActive: true })
      .sort({ 'times.0': 1 }) // Classer par le premier horaire
      .exec();

    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];

    return reminders
      .map((r) => {
        const reminderData = this.formatReminder(r);
        // Add completion status for today
        const todayCompletion = r.completionHistory?.find(
          (h) => h.date.toISOString().split('T')[0] === todayStr,
        );

        return {
          ...reminderData,
          completedToday: todayCompletion?.completed || false,
          completedAt: todayCompletion?.completedAt,
        };
      })
      .filter((r) => {
        // Filter based on frequency
        if (r.frequency === ReminderFrequency.DAILY) return true;
        if (r.frequency === ReminderFrequency.INTERVAL) return true;
        if (r.frequency === ReminderFrequency.WEEKLY) {
          const dayName = today
            .toLocaleDateString('en-US', { weekday: 'long' })
            .toLowerCase();
          return r.daysOfWeek?.includes(dayName);
        }
        return true;
      });
  }

  /**
   * Update a task reminder
   */
  async update(reminderId: string, dto: UpdateTaskReminderDto, userId: string) {
    const reminder = await this.taskReminderModel.findById(reminderId);
    if (!reminder) {
      throw new NotFoundException('Reminder not found');
    }

    // Verify authorization
    await this.verifyAccess(reminder.childId.toString(), userId);

    Object.assign(reminder, dto);
    await reminder.save();

    return this.formatReminder(reminder);
  }

  /**
   * Mark task as completed or incomplete
   */
  async completeTask(
    dto: CompleteTaskDto,
    userId: string,
    proofImage?: { buffer: Buffer; originalname: string },
  ) {
    const reminder = await this.taskReminderModel.findById(dto.reminderId);
    if (!reminder) {
      throw new NotFoundException('Reminder not found');
    }

    // Verify authorization
    await this.verifyAccess(reminder.childId.toString(), userId);

    const completionDate = new Date(dto.date);
    completionDate.setUTCHours(0, 0, 0, 0); // Normalize to UTC midnight
    const dateStr = completionDate.toISOString().split('T')[0];

    let proofImagePath: string | undefined;

    // Save proof image if provided
    if (proofImage && dto.completed) {
      const uploadsDir = path.join(process.cwd(), 'uploads', 'proof-images');

      // Create directory if it doesn't exist
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const timestamp = Date.now();
      const filename = `${reminder._id.toString()}_${timestamp}_${proofImage.originalname}`;
      const filepath = path.join(uploadsDir, filename);

      // Save file
      fs.writeFileSync(filepath, proofImage.buffer);

      // Store relative path
      proofImagePath = `/uploads/proof-images/${filename}`;
    }

    // Find existing completion for this date
    const existingIndex =
      reminder.completionHistory?.findIndex(
        (h) => h.date.toISOString().split('T')[0] === dateStr,
      ) ?? -1;

    let targetIndex = -1;
    if (existingIndex >= 0 && reminder.completionHistory) {
      // Update existing
      reminder.completionHistory[existingIndex] = {
        date: completionDate,
        completed: dto.completed,
        completedAt: dto.completed ? new Date() : undefined,
        feedback: dto.feedback,
        proofImageUrl: proofImagePath,
      };
      targetIndex = existingIndex;
    } else {
      // Add new
      if (!reminder.completionHistory) {
        reminder.completionHistory = [];
      }
      reminder.completionHistory.push({
        date: completionDate,
        completed: dto.completed,
        completedAt: dto.completed ? new Date() : undefined,
        feedback: dto.feedback,
        proofImageUrl: proofImagePath,
      });
      targetIndex = reminder.completionHistory.length - 1;
    }

    // Trigger AI verification if it's a medication task and has a proof image
    this.logger.log(
      `Checking verification: type=${reminder.type}, hasPath=${!!proofImagePath}, completed=${dto.completed}`,
    );

    if (
      reminder.type === ReminderType.MEDICATION &&
      proofImagePath &&
      dto.completed &&
      targetIndex >= 0
    ) {
      try {
        const verificationResult =
          await this.medicationVerificationService.verifyMedication(
            proofImagePath,
            { title: reminder.title, description: reminder.description },
          );

        reminder.completionHistory[targetIndex].verificationStatus =
          verificationResult.status;
        reminder.completionHistory[targetIndex].verificationMetadata = {
          ...verificationResult.metadata,
          reasoning: verificationResult.reasoning,
        };
        reminder.markModified('completionHistory');
        this.logger.log(
          `Verification saved: status=${verificationResult.status} for index ${targetIndex}`,
        );
      } catch (error) {
        this.logger.error('AI Verification failed:', error);
        if (reminder.completionHistory[targetIndex]) {
          reminder.completionHistory[targetIndex].verificationStatus =
            'UNCERTAIN';
          reminder.completionHistory[targetIndex].verificationMetadata = {
            reasoning:
              "L'analyse automatique a échoué. Un humain doit vérifier la photo.",
          };
        }
        reminder.markModified('completionHistory');
      }
    }

    await reminder.save();

    return {
      message: dto.completed
        ? 'Task marked as completed with proof'
        : 'Task marked as incomplete',
      reminder: this.formatReminder(reminder),
      proofImageUrl: proofImagePath,
    };
  }

  /**
   * Delete (deactivate) reminder
   */
  async delete(reminderId: string, userId: string) {
    const reminder = await this.taskReminderModel.findById(reminderId);
    if (!reminder) {
      throw new NotFoundException('Reminder not found');
    }

    // Verify authorization
    await this.verifyAccess(reminder.childId.toString(), userId);

    reminder.isActive = false;
    await reminder.save();

    return { message: 'Reminder deactivated successfully' };
  }

  /**
   * Get completion statistics for a child
   */
  async getCompletionStats(childId: string, userId: string, days: number = 7) {
    await this.verifyAccess(childId, userId);

    const reminders = await this.taskReminderModel
      .find({ childId: new Types.ObjectId(childId), isActive: true })
      .exec();

    const now = new Date();
    const startDate = new Date(now);
    startDate.setDate(startDate.getDate() - days);

    const stats = {
      totalReminders: reminders.length,
      totalTasks: 0,
      completedTasks: 0,
      completionRate: 0,
      dailyStats: [] as Array<{
        date: string;
        total: number;
        completed: number;
      }>,
    };

    // Calculate stats for each day
    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];

      let dayTotal = 0;
      let dayCompleted = 0;

      reminders.forEach((reminder) => {
        // Check if reminder was active on this day
        const reminderCreated = new Date(reminder.createdAt || date);
        if (reminderCreated <= date) {
          dayTotal++;

          const completion = reminder.completionHistory?.find(
            (h) => h.date.toISOString().split('T')[0] === dateStr,
          );

          if (completion?.completed) {
            dayCompleted++;
          }
        }
      });

      stats.dailyStats.push({
        date: dateStr,
        total: dayTotal,
        completed: dayCompleted,
      });

      stats.totalTasks += dayTotal;
      stats.completedTasks += dayCompleted;
    }

    stats.completionRate =
      stats.totalTasks > 0
        ? Math.round((stats.completedTasks / stats.totalTasks) * 100)
        : 0;

    return stats;
  }

  /**
   * Verify user has access to child's reminders
   */
  private async verifyAccess(childId: string, userId: string) {
    const child = await this.childModel.findById(childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new ForbiddenException('User not found');
    }

    const isParent = child.parentId?.toString() === userId;
    const isHealthcare = [
      'doctor',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
    ].includes(user.role);

    if (!isParent && !isHealthcare) {
      throw new ForbiddenException('Not authorized to access child reminders');
    }
  }

  /**
   * Format reminder for response
   */
  private formatReminder(reminder: TaskReminderDocument) {
    return {
      id: reminder._id.toString(),
      childId: reminder.childId.toString(),
      createdBy: reminder.createdBy.toString(),
      type: reminder.type,
      title: reminder.title,
      description: reminder.description,
      icon: reminder.icon,
      color: reminder.color,
      frequency: reminder.frequency,
      times: reminder.times,
      intervalMinutes: reminder.intervalMinutes,
      daysOfWeek: reminder.daysOfWeek,
      soundEnabled: reminder.soundEnabled,
      vibrationEnabled: reminder.vibrationEnabled,
      isActive: reminder.isActive,
      linkedNutritionPlanId: reminder.linkedNutritionPlanId?.toString(),
      completionHistory: reminder.completionHistory?.map((c) => ({
        date: c.date,
        completed: c.completed,
        completedAt: c.completedAt,
        feedback: c.feedback,
        proofImageUrl: c.proofImageUrl,
        verificationStatus: c.verificationStatus,
        verificationMetadata: c.verificationMetadata,
      })),
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    };
  }
}
