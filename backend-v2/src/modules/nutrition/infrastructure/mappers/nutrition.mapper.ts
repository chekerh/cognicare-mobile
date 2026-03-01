import {
  NutritionPlanEntity,
  TaskReminderEntity,
  CompletionEntry,
} from "../../domain";

export class NutritionPlanMapper {
  static toDomain(raw: any): NutritionPlanEntity {
    return NutritionPlanEntity.reconstitute(raw._id?.toString() ?? raw.id, {
      childId: raw.childId?.toString(),
      createdBy: raw.createdBy?.toString(),
      dailyWaterGoal: raw.dailyWaterGoal ?? 6,
      waterReminderInterval: raw.waterReminderInterval ?? 120,
      breakfast: raw.breakfast ?? [],
      breakfastTime: raw.breakfastTime,
      lunch: raw.lunch ?? [],
      lunchTime: raw.lunchTime,
      dinner: raw.dinner ?? [],
      dinnerTime: raw.dinnerTime,
      snacks: raw.snacks ?? [],
      allergies: raw.allergies ?? [],
      restrictions: raw.restrictions ?? [],
      preferences: raw.preferences ?? [],
      medications: raw.medications ?? [],
      specialNotes: raw.specialNotes,
      isActive: raw.isActive ?? true,
      createdAt: raw.createdAt ? new Date(raw.createdAt) : undefined,
      updatedAt: raw.updatedAt ? new Date(raw.updatedAt) : undefined,
    });
  }

  static toPersistence(entity: NutritionPlanEntity): Record<string, any> {
    return {
      childId: entity.childId,
      createdBy: entity.createdBy,
      dailyWaterGoal: entity.dailyWaterGoal,
      waterReminderInterval: entity.waterReminderInterval,
      breakfast: entity.breakfast,
      breakfastTime: entity.breakfastTime,
      lunch: entity.lunch,
      lunchTime: entity.lunchTime,
      dinner: entity.dinner,
      dinnerTime: entity.dinnerTime,
      snacks: entity.snacks,
      allergies: entity.allergies,
      restrictions: entity.restrictions,
      preferences: entity.preferences,
      medications: entity.medications,
      specialNotes: entity.specialNotes,
      isActive: entity.isActive,
    };
  }
}

export class TaskReminderMapper {
  static toDomain(raw: any): TaskReminderEntity {
    const history: CompletionEntry[] = (raw.completionHistory ?? []).map(
      (h: any) => ({
        date: new Date(h.date),
        completed: h.completed,
        completedAt: h.completedAt ? new Date(h.completedAt) : undefined,
        feedback: h.feedback,
        proofImageUrl: h.proofImageUrl,
        verificationStatus: h.verificationStatus,
        verificationMetadata: h.verificationMetadata,
      }),
    );

    return TaskReminderEntity.reconstitute(raw._id?.toString() ?? raw.id, {
      childId: raw.childId?.toString(),
      createdBy: raw.createdBy?.toString(),
      type: raw.type,
      title: raw.title,
      description: raw.description,
      icon: raw.icon,
      color: raw.color,
      frequency: raw.frequency,
      times: raw.times ?? [],
      intervalMinutes: raw.intervalMinutes,
      daysOfWeek: raw.daysOfWeek ?? [],
      soundEnabled: raw.soundEnabled ?? true,
      vibrationEnabled: raw.vibrationEnabled ?? true,
      completionHistory: history,
      isActive: raw.isActive ?? true,
      linkedNutritionPlanId: raw.linkedNutritionPlanId?.toString(),
      createdAt: raw.createdAt ? new Date(raw.createdAt) : undefined,
      updatedAt: raw.updatedAt ? new Date(raw.updatedAt) : undefined,
    });
  }

  static toPersistence(entity: TaskReminderEntity): Record<string, any> {
    return {
      childId: entity.childId,
      createdBy: entity.createdBy,
      type: entity.type,
      title: entity.title,
      description: entity.description,
      icon: entity.icon,
      color: entity.color,
      frequency: entity.frequency,
      times: entity.times,
      intervalMinutes: entity.intervalMinutes,
      daysOfWeek: entity.daysOfWeek,
      soundEnabled: entity.soundEnabled,
      vibrationEnabled: entity.vibrationEnabled,
      completionHistory: entity.completionHistory,
      isActive: entity.isActive,
      linkedNutritionPlanId: entity.linkedNutritionPlanId,
    };
  }
}
