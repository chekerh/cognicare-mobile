import { Injectable, ForbiddenException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";

const PLAY_TIME_GOAL_MINUTES = 60;

const GAME_TYPE_LABELS: Record<string, string> = {
  matching: "Puzzle terminé",
  shape_sorting: "Tri des formes",
  star_tracer: "Tracé étoile",
  basket_sort: "Tri panier",
  child_mode: "Mode enfant",
};

export interface DashboardActivity {
  id: string;
  type: "game" | "task";
  title: string;
  subtitle: string;
  time: string;
  badge?: { label: string; color: string };
}
export interface DashboardBadge {
  id: string;
  name: string;
  description?: string;
  iconUrl?: string;
  earnedAt: string;
}
export interface EngagementDashboardDto {
  childId: string;
  childName: string;
  playTimeTodayMinutes: number;
  playTimeGoalMinutes: number;
  focusMessage: string;
  recentActivities: DashboardActivity[];
  badges: DashboardBadge[];
}

@Injectable()
export class EngagementService {
  constructor(
    @InjectModel("Child") private childModel: Model<any>,
    @InjectModel("GameSession") private gameSessionModel: Model<any>,
    @InjectModel("TaskReminder") private taskReminderModel: Model<any>,
    @InjectModel("ChildBadge") private childBadgeModel: Model<any>,
    @InjectModel("Badge") private badgeModel: Model<any>,
    @InjectModel("User") private userModel: Model<any>,
  ) {}

  async getDashboard(
    userId: string,
    childId?: string,
  ): Promise<EngagementDashboardDto> {
    const child = await this.resolveChild(userId, childId);
    if (!child) return this.emptyDashboard();

    const cid = child._id;
    const todayStart = this.getStartOfDay(new Date());
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);
    const yesterdayStart = new Date(todayStart);
    yesterdayStart.setDate(yesterdayStart.getDate() - 1);
    const yesterdayEnd = new Date(todayStart);

    const [
      playTimeTodaySec,
      playTimeYesterdaySec,
      sessionsToday,
      remindersWithCompletion,
      badges,
    ] = await Promise.all([
      this.getPlayTimeInRange(cid, todayStart, todayEnd),
      this.getPlayTimeInRange(cid, yesterdayStart, yesterdayEnd),
      this.gameSessionModel
        .find({ childId: cid, createdAt: { $gte: todayStart, $lt: todayEnd } })
        .sort({ createdAt: -1 })
        .lean()
        .exec(),
      this.getTodayCompletedReminders(cid, todayStart),
      this.getChildBadges(cid),
    ]);

    const playTimeTodayMinutes = Math.floor(playTimeTodaySec / 60);
    const playTimeYesterdayMinutes = Math.floor(playTimeYesterdaySec / 60);
    const childName = child.fullName || "L'enfant";
    const focusMessage = this.buildFocusMessage(
      childName,
      playTimeTodayMinutes,
      playTimeYesterdayMinutes,
    );

    const activities: DashboardActivity[] = [];
    for (const s of sessionsToday as any[]) {
      activities.push({
        id: s._id.toString(),
        type: "game",
        title: GAME_TYPE_LABELS[s.gameType] || s.gameType,
        subtitle: s.level
          ? `Niveau ${s.level} réussi en ${Math.round((s.timeSpentSeconds || 0) / 60)} min.`
          : `Session de ${Math.round((s.timeSpentSeconds || 0) / 60)} min.`,
        time: this.formatTime(s.createdAt),
        badge: s.completed
          ? { label: `AGILITÉ COGNITIVE +${s.score || 0}`, color: "green" }
          : undefined,
      });
    }
    for (const r of remindersWithCompletion) {
      activities.push({
        id: `${r.reminderId}-${r.completedAt.toISOString()}`,
        type: "task",
        title: r.title,
        subtitle: r.description || this.reminderTypeSubtitle(r.reminderType),
        time: this.formatTime(r.completedAt),
      });
    }
    activities.sort((a, b) => b.time.localeCompare(a.time));
    return {
      childId: cid.toString(),
      childName: child.fullName || "Enfant",
      playTimeTodayMinutes,
      playTimeGoalMinutes: PLAY_TIME_GOAL_MINUTES,
      focusMessage,
      recentActivities: activities.slice(0, 10),
      badges,
    };
  }

  private async resolveChild(
    userId: string,
    childId?: string,
  ): Promise<{
    _id: Types.ObjectId;
    fullName: string;
    [key: string]: any;
  } | null> {
    const user = await this.userModel.findById(userId).lean().exec();
    if (!user) return null;
    if (childId) {
      const child = (await this.childModel
        .findById(childId)
        .lean()
        .exec()) as any;
      if (!child) return null;
      if (child.parentId?.toString() !== userId)
        throw new ForbiddenException("Not authorized to access this child");
      return child;
    }
    const children = (await this.childModel
      .find({ parentId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(1)
      .lean()
      .exec()) as any[];
    return children[0] || null;
  }

  private getPlayTimeInRange(
    childId: Types.ObjectId,
    start: Date,
    end: Date,
  ): Promise<number> {
    return this.gameSessionModel
      .aggregate([
        { $match: { childId, createdAt: { $gte: start, $lt: end } } },
        { $group: { _id: null, total: { $sum: "$timeSpentSeconds" } } },
      ])
      .then((r) => (r[0]?.total ?? 0) as number);
  }

  private async getTodayCompletedReminders(
    childId: Types.ObjectId,
    todayStart: Date,
  ): Promise<
    Array<{
      reminderId: string;
      title: string;
      description?: string;
      reminderType: string;
      completedAt: Date;
    }>
  > {
    const reminders = await this.taskReminderModel
      .find({ childId, isActive: true })
      .lean()
      .exec();
    const todayStr = todayStart.toISOString().split("T")[0];
    const out: any[] = [];
    for (const r of reminders as any[]) {
      const hist = r.completionHistory || [];
      const entry = hist.find(
        (h: any) =>
          h.date &&
          new Date(h.date).toISOString().split("T")[0] === todayStr &&
          h.completed,
      );
      if (entry?.completedAt)
        out.push({
          reminderId: r._id.toString(),
          title: r.title || "Tâche",
          description: r.description,
          reminderType: r.type || "custom",
          completedAt: new Date(entry.completedAt),
        });
    }
    return out;
  }

  private reminderTypeSubtitle(type: string): string {
    const map: Record<string, string> = {
      activity: "Activité réalisée.",
      homework: "Devoir terminé.",
      hygiene: "Routine hygiène.",
      medication: "Prise effectuée.",
      meal: "Repas pris.",
      water: "Eau bue.",
    };
    return map[type] ?? "Tâche complétée.";
  }

  private async getChildBadges(
    childId: Types.ObjectId,
  ): Promise<DashboardBadge[]> {
    const childBadges = await this.childBadgeModel
      .find({ childId })
      .sort({ earnedAt: -1 })
      .limit(20)
      .populate("badgeId")
      .lean()
      .exec();
    return childBadges.map((cb: any) => ({
      id: cb.badgeIdString || cb._id.toString(),
      name: cb.badgeId?.name || "Badge",
      description: cb.badgeId?.description,
      iconUrl: cb.badgeId?.iconUrl,
      earnedAt:
        cb.earnedAt || cb.createdAt
          ? new Date(cb.earnedAt || cb.createdAt).toISOString()
          : new Date().toISOString(),
    }));
  }

  private buildFocusMessage(
    childName: string,
    todayMinutes: number,
    yesterdayMinutes: number,
  ): string {
    const name = childName.trim() || "L'enfant";
    if (yesterdayMinutes <= 0) {
      if (todayMinutes > 0)
        return `${name} a bien repris ! Premier temps de jeu enregistré aujourd'hui.`;
      return "Aucun temps de jeu encore aujourd'hui. Lance une activité pour commencer !";
    }
    const pct = Math.round(
      ((todayMinutes - yesterdayMinutes) / yesterdayMinutes) * 100,
    );
    if (pct > 0)
      return `${name} est très concentré ! +${pct}% de temps de jeu aujourd'hui par rapport à hier.`;
    if (pct < 0)
      return `Aujourd'hui : ${Math.abs(pct)}% de temps de jeu en moins qu'hier. Tu peux reprendre quand tu veux !`;
    return `${name} garde le rythme. Continue comme ça !`;
  }

  private getStartOfDay(d: Date): Date {
    const x = new Date(d);
    x.setHours(0, 0, 0, 0);
    return x;
  }
  private formatTime(d: Date): string {
    const date = typeof d === "string" ? new Date(d) : d;
    return `${date.getHours().toString().padStart(2, "0")}:${date.getMinutes().toString().padStart(2, "0")}`;
  }
  private emptyDashboard(): EngagementDashboardDto {
    return {
      childId: "",
      childName: "",
      playTimeTodayMinutes: 0,
      playTimeGoalMinutes: PLAY_TIME_GOAL_MINUTES,
      focusMessage:
        "Ajoute un enfant dans ton profil pour voir son tableau d'engagement.",
      recentActivities: [],
      badges: [],
    };
  }
}
