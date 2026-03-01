import { Inject, Injectable, Logger } from '@nestjs/common';
import { ValidationException } from '@/core/domain';
import {
  NutritionPlanEntity,
  TaskReminderEntity,
  ReminderType,
  INutritionPlanRepository,
  ITaskReminderRepository,
  CompletionEntry,
  ReminderFrequency,
} from '../../domain';
import {
  CreateNutritionPlanDto,
  UpdateNutritionPlanDto,
  CreateTaskReminderDto,
  UpdateTaskReminderDto,
  CompleteTaskDto,
} from '../dto/nutrition.dto';

export const NUTRITION_PLAN_REPOSITORY_TOKEN = Symbol('INutritionPlanRepository');
export const TASK_REMINDER_REPOSITORY_TOKEN = Symbol('ITaskReminderRepository');

/* ─── Nutrition Plan Use Cases ─── */

@Injectable()
export class CreateNutritionPlanUseCase {
  constructor(@Inject(NUTRITION_PLAN_REPOSITORY_TOKEN) private readonly repo: INutritionPlanRepository) {}

  async execute(dto: CreateNutritionPlanDto, userId: string): Promise<NutritionPlanEntity> {
    const plan = NutritionPlanEntity.create({
      childId: dto.childId,
      createdBy: userId,
      dailyWaterGoal: dto.dailyWaterGoal ?? 6,
      waterReminderInterval: dto.waterReminderInterval ?? 120,
      breakfast: dto.breakfast ?? [],
      breakfastTime: dto.breakfastTime,
      lunch: dto.lunch ?? [],
      lunchTime: dto.lunchTime,
      dinner: dto.dinner ?? [],
      dinnerTime: dto.dinnerTime,
      snacks: dto.snacks ?? [],
      allergies: dto.allergies ?? [],
      restrictions: dto.restrictions ?? [],
      preferences: dto.preferences ?? [],
      medications: dto.medications ?? [],
      specialNotes: dto.specialNotes,
    });
    return this.repo.save(plan);
  }
}

@Injectable()
export class GetNutritionPlanByChildUseCase {
  constructor(@Inject(NUTRITION_PLAN_REPOSITORY_TOKEN) private readonly repo: INutritionPlanRepository) {}

  async execute(childId: string): Promise<NutritionPlanEntity> {
    const plan = await this.repo.findByChildId(childId, true);
    if (!plan) throw new ValidationException('No active nutrition plan found for this child');
    return plan;
  }
}

@Injectable()
export class UpdateNutritionPlanUseCase {
  constructor(@Inject(NUTRITION_PLAN_REPOSITORY_TOKEN) private readonly repo: INutritionPlanRepository) {}

  async execute(planId: string, dto: UpdateNutritionPlanDto): Promise<NutritionPlanEntity> {
    const plan = await this.repo.findById(planId);
    if (!plan) throw new ValidationException('Nutrition plan not found');
    plan.update(dto);
    return this.repo.update(plan);
  }
}

@Injectable()
export class DeleteNutritionPlanUseCase {
  constructor(@Inject(NUTRITION_PLAN_REPOSITORY_TOKEN) private readonly repo: INutritionPlanRepository) {}

  async execute(planId: string): Promise<{ message: string }> {
    const plan = await this.repo.findById(planId);
    if (!plan) throw new ValidationException('Nutrition plan not found');
    plan.deactivate();
    await this.repo.update(plan);
    return { message: 'Nutrition plan deactivated successfully' };
  }
}

/* ─── Task Reminder Use Cases ─── */

@Injectable()
export class CreateTaskReminderUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(dto: CreateTaskReminderDto, userId: string): Promise<TaskReminderEntity> {
    const reminder = TaskReminderEntity.create({
      childId: dto.childId,
      createdBy: userId,
      type: dto.type,
      title: dto.title,
      description: dto.description,
      icon: dto.icon,
      color: dto.color,
      frequency: dto.frequency,
      times: dto.times ?? [],
      intervalMinutes: dto.intervalMinutes,
      daysOfWeek: dto.daysOfWeek ?? [],
      soundEnabled: dto.soundEnabled ?? true,
      vibrationEnabled: dto.vibrationEnabled ?? true,
      linkedNutritionPlanId: dto.linkedNutritionPlanId,
    });
    return this.repo.save(reminder);
  }
}

@Injectable()
export class GetRemindersByChildUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(childId: string): Promise<TaskReminderEntity[]> {
    return this.repo.findByChildId(childId, true);
  }
}

@Injectable()
export class GetTodayRemindersUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(childId: string): Promise<any[]> {
    const reminders = await this.repo.findByChildId(childId, true);
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];

    return reminders
      .map((r) => {
        const todayCompletion = r.completionHistory.find(
          (h) => h.date.toISOString().split('T')[0] === todayStr,
        );
        return {
          ...this.toOutput(r),
          completedToday: todayCompletion?.completed || false,
          completedAt: todayCompletion?.completedAt,
        };
      })
      .filter((r) => {
        if (r.frequency === ReminderFrequency.DAILY) return true;
        if (r.frequency === ReminderFrequency.INTERVAL) return true;
        if (r.frequency === ReminderFrequency.WEEKLY) {
          const day = today.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
          return r.daysOfWeek?.includes(day);
        }
        return true;
      });
  }

  private toOutput(r: TaskReminderEntity) {
    return {
      id: r.id, childId: r.childId, type: r.type, title: r.title,
      description: r.description, icon: r.icon, color: r.color,
      frequency: r.frequency, times: r.times, intervalMinutes: r.intervalMinutes,
      daysOfWeek: r.daysOfWeek, soundEnabled: r.soundEnabled, vibrationEnabled: r.vibrationEnabled,
      isActive: r.isActive, linkedNutritionPlanId: r.linkedNutritionPlanId,
      completionHistory: r.completionHistory, createdAt: r.createdAt, updatedAt: r.updatedAt,
    };
  }
}

@Injectable()
export class UpdateTaskReminderUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(reminderId: string, dto: UpdateTaskReminderDto): Promise<TaskReminderEntity> {
    const reminder = await this.repo.findById(reminderId);
    if (!reminder) throw new ValidationException('Reminder not found');
    reminder.update(dto);
    return this.repo.update(reminder);
  }
}

@Injectable()
export class CompleteTaskUseCase {
  private readonly logger = new Logger(CompleteTaskUseCase.name);

  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(
    dto: CompleteTaskDto,
    userId: string,
    proofImage?: { buffer: Buffer; originalname: string },
    verifyMedication?: (imagePath: string, context: any) => Promise<any>,
  ): Promise<any> {
    const reminder = await this.repo.findById(dto.reminderId);
    if (!reminder) throw new ValidationException('Reminder not found');

    const completionDate = new Date(dto.date);
    completionDate.setUTCHours(0, 0, 0, 0);

    let proofImagePath: string | undefined;
    if (proofImage && dto.completed) {
      const fs = await import('fs');
      const path = await import('path');
      const uploadsDir = path.join(process.cwd(), 'uploads', 'proof-images');
      if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
      const filename = `${reminder.id}_${Date.now()}_${proofImage.originalname}`;
      fs.writeFileSync(path.join(uploadsDir, filename), proofImage.buffer);
      proofImagePath = `/uploads/proof-images/${filename}`;
    }

    const entry: CompletionEntry = {
      date: completionDate,
      completed: dto.completed,
      completedAt: dto.completed ? new Date() : undefined,
      feedback: dto.feedback,
      proofImageUrl: proofImagePath,
    };

    const idx = reminder.addCompletion(entry);

    // AI medication verification
    if (reminder.type === ReminderType.MEDICATION && proofImagePath && dto.completed && verifyMedication) {
      try {
        const result = await verifyMedication(proofImagePath, { title: reminder.title, description: reminder.description });
        reminder.setVerification(idx, result.status, { ...result.metadata, reasoning: result.reasoning });
      } catch (error) {
        this.logger.error('AI Verification failed:', error);
        reminder.setVerification(idx, 'UNCERTAIN', { reasoning: "L'analyse automatique a échoué." });
      }
    }

    const updated = await this.repo.update(reminder);
    return {
      message: dto.completed ? 'Task marked as completed with proof' : 'Task marked as incomplete',
      reminder: updated,
      proofImageUrl: proofImagePath,
    };
  }
}

@Injectable()
export class DeleteTaskReminderUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(reminderId: string): Promise<{ message: string }> {
    const reminder = await this.repo.findById(reminderId);
    if (!reminder) throw new ValidationException('Reminder not found');
    reminder.deactivate();
    await this.repo.update(reminder);
    return { message: 'Reminder deactivated successfully' };
  }
}

@Injectable()
export class GetCompletionStatsUseCase {
  constructor(@Inject(TASK_REMINDER_REPOSITORY_TOKEN) private readonly repo: ITaskReminderRepository) {}

  async execute(childId: string, days: number = 7): Promise<any> {
    const reminders = await this.repo.findByChildId(childId, true);
    const now = new Date();
    const startDate = new Date(now);
    startDate.setDate(startDate.getDate() - days);

    const stats = {
      totalReminders: reminders.length,
      totalTasks: 0,
      completedTasks: 0,
      completionRate: 0,
      dailyStats: [] as Array<{ date: string; total: number; completed: number }>,
    };

    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      let dayTotal = 0, dayCompleted = 0;

      reminders.forEach((r) => {
        const created = r.createdAt ? new Date(r.createdAt) : date;
        if (created <= date) {
          dayTotal++;
          const completion = r.completionHistory.find(
            (h) => h.date.toISOString().split('T')[0] === dateStr,
          );
          if (completion?.completed) dayCompleted++;
        }
      });
      stats.dailyStats.push({ date: dateStr, total: dayTotal, completed: dayCompleted });
      stats.totalTasks += dayTotal;
      stats.completedTasks += dayCompleted;
    }

    stats.completionRate = stats.totalTasks > 0 ? Math.round((stats.completedTasks / stats.totalTasks) * 100) : 0;
    return stats;
  }
}
