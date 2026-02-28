import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import {
  SpecializedPlan,
  SpecializedPlanDocument,
} from '../specialized-plans/schemas/specialized-plan.schema';
import {
  TaskReminder,
  TaskReminderDocument,
} from '../nutrition/schemas/task-reminder.schema';
import { SpecializedPlansService } from '../specialized-plans/specialized-plans.service';

/** Numeric progress hints for LLM (prompt only, no PII). */
export interface ProgressNumericSummary {
  PECS?: { trialsPass: number; trialsTotal: number; itemCount: number };
  TEACCH?: { goalsAtTarget: number; totalGoals: number };
  SkillTracker?: { currentPercent: number; targetPercent: number };
  Activity?: { completed: number; inProgress: number };
}

export interface ProgressContext {
  child: {
    ageYears: number;
    diagnosis?: string;
    gender: string;
  };
  plans: Array<{
    planId: string;
    type: string;
    title: string;
    content: unknown; // Activity plans may include parentFeedback?, completedAt? for AI context
    sessionNotes?: string;
  }>;
  /** Short numeric summary to help LLM produce consistent phase/date estimates. */
  progressNumericSummary?: ProgressNumericSummary;
  taskReminders: Array<{
    title: string;
    type: string;
    completionSummary: {
      total: number;
      completed: number;
      recent: Array<{ date: string; completed: boolean }>;
      /** Number of entries where parents left textual feedback */
      feedbackCount: number;
      /** Latest non-empty feedback text, if any (may be truncated in the prompt) */
      latestFeedback?: string;
    };
  }>;
}

function ageFromDateOfBirth(dateOfBirth: Date): number {
  const today = new Date();
  const dob = new Date(dateOfBirth);
  let age = today.getFullYear() - dob.getFullYear();
  const m = today.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--;
  return Math.max(0, age);
}

@Injectable()
export class ProgressContextService {
  constructor(
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(TaskReminder.name)
    private taskReminderModel: Model<TaskReminderDocument>,
    private specializedPlansService: SpecializedPlansService,
  ) {}

  async buildContext(
    childId: string,
    orgId: string | undefined,
  ): Promise<ProgressContext> {
    const child = await this.childModel
      .findOne({ _id: childId, deletedAt: { $in: [null, undefined] } })
      .lean()
      .exec();
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    const plans = await this.specializedPlansService.getPlansByChild(
      childId,
      orgId,
    );
    const plansForContext = (plans as SpecializedPlanDocument[]).map((p) => ({
      planId: p._id.toString(),
      type: p.type,
      title: p.title,
      content: p.content,
      sessionNotes: (p as any).sessionNotes,
    }));

    const reminders = await this.taskReminderModel
      .find({ childId: new Types.ObjectId(childId), isActive: true })
      .lean()
      .exec();

    const taskReminders = reminders.map((r: any) => {
      const history = r.completionHistory || [];
      const recent = history
        .slice(-14)
        .map((h: { date: Date; completed: boolean }) => ({
          date: h.date ? new Date(h.date).toISOString().slice(0, 10) : '',
          completed: !!h.completed,
        }));
      const completed = history.filter(
        (h: { completed: boolean }) => h.completed,
      ).length;
      const feedbackEntries = history.filter(
        (h: { feedback?: string }) =>
          typeof h.feedback === 'string' && h.feedback.trim().length > 0,
      );
      const feedbackCount = feedbackEntries.length;
      const latestFeedback =
        feedbackCount > 0
          ? String(feedbackEntries[feedbackEntries.length - 1].feedback).slice(
              0,
              280,
            )
          : undefined;
      return {
        title: r.title,
        type: r.type,
        completionSummary: {
          total: history.length,
          completed,
          recent,
          feedbackCount,
          latestFeedback,
        },
      };
    });

    const ageYears = ageFromDateOfBirth(child.dateOfBirth);

    const progressNumericSummary =
      this.computeProgressNumericSummary(plansForContext);

    return {
      child: {
        ageYears,
        diagnosis: child.diagnosis,
        gender: child.gender,
      },
      plans: plansForContext,
      progressNumericSummary,
      taskReminders,
    };
  }

  private computeProgressNumericSummary(
    plans: Array<{ type: string; content: unknown }>,
  ): ProgressNumericSummary {
    const out: ProgressNumericSummary = {};
    for (const p of plans) {
      const c = p.content as Record<string, unknown> | undefined;
      if (!c) continue;
      if (p.type === 'PECS') {
        const items = (c.items as Array<{ trials?: unknown[] }>) ?? [];
        let pass = 0,
          total = 0;
        for (const it of items) {
          const trials = it?.trials;
          if (trials) {
            for (const t of trials) {
              if (t === true) pass++;
              if (t === true || t === false) total++;
            }
          }
        }
        out.PECS = {
          trialsPass: pass,
          trialsTotal: total,
          itemCount: items.length,
        };
      } else if (p.type === 'TEACCH') {
        const goals =
          (c.goals as Array<{ current?: number; target?: number }>) ?? [];
        let atTarget = 0;
        for (const g of goals) {
          const cur = typeof g?.current === 'number' ? g.current : 0;
          const tgt = typeof g?.target === 'number' ? g.target : 0;
          if (tgt > 0 && cur >= tgt) atTarget++;
        }
        out.TEACCH = { goalsAtTarget: atTarget, totalGoals: goals.length };
      } else if (p.type === 'SkillTracker') {
        const cur = typeof c.currentPercent === 'number' ? c.currentPercent : 0;
        const tgt = typeof c.targetPercent === 'number' ? c.targetPercent : 100;
        out.SkillTracker = { currentPercent: cur, targetPercent: tgt };
      } else if (p.type === 'Activity') {
        const status = c.status as string | undefined;
        const completed = status === 'completed' ? 1 : 0;
        const inProgress = status === 'in_progress' ? 1 : 0;
        out.Activity = { completed, inProgress };
      }
    }
    return out;
  }
}
