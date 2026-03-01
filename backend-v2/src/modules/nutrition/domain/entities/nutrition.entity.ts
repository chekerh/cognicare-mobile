import { Entity } from '@/core/domain';

/* ─── NutritionPlanEntity ─── */
export interface MedicationItem {
  name: string;
  dosage: string;
  time: string;
  withFood?: boolean;
  notes?: string;
}

export interface SnackItem {
  time: string;
  items: string[];
}

export interface NutritionPlanProps {
  childId: string;
  createdBy: string;
  dailyWaterGoal: number;
  waterReminderInterval: number;
  breakfast: string[];
  breakfastTime?: string;
  lunch: string[];
  lunchTime?: string;
  dinner: string[];
  dinnerTime?: string;
  snacks: SnackItem[];
  allergies: string[];
  restrictions: string[];
  preferences: string[];
  medications: MedicationItem[];
  specialNotes?: string;
  isActive: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export class NutritionPlanEntity extends Entity<string> {
  private props: NutritionPlanProps;

  private constructor(id: string, props: NutritionPlanProps) {
    super(id);
    this.props = props;
  }

  static create(props: Omit<NutritionPlanProps, 'isActive' | 'createdAt' | 'updatedAt'>, id?: string): NutritionPlanEntity {
    return new NutritionPlanEntity(id ?? Entity.generateId(), { ...props, isActive: true });
  }

  static reconstitute(id: string, props: NutritionPlanProps): NutritionPlanEntity {
    return new NutritionPlanEntity(id, props);
  }

  get childId() { return this.props.childId; }
  get createdBy() { return this.props.createdBy; }
  get dailyWaterGoal() { return this.props.dailyWaterGoal; }
  get waterReminderInterval() { return this.props.waterReminderInterval; }
  get breakfast() { return this.props.breakfast; }
  get breakfastTime() { return this.props.breakfastTime; }
  get lunch() { return this.props.lunch; }
  get lunchTime() { return this.props.lunchTime; }
  get dinner() { return this.props.dinner; }
  get dinnerTime() { return this.props.dinnerTime; }
  get snacks() { return this.props.snacks; }
  get allergies() { return this.props.allergies; }
  get restrictions() { return this.props.restrictions; }
  get preferences() { return this.props.preferences; }
  get medications() { return this.props.medications; }
  get specialNotes() { return this.props.specialNotes; }
  get isActive() { return this.props.isActive; }
  get createdAt() { return this.props.createdAt; }
  get updatedAt() { return this.props.updatedAt; }

  update(data: Partial<NutritionPlanProps>): void {
    Object.assign(this.props, data);
  }

  deactivate(): void {
    this.props.isActive = false;
  }
}

/* ─── TaskReminderEntity ─── */
export enum ReminderType {
  WATER = 'water',
  MEAL = 'meal',
  MEDICATION = 'medication',
  HOMEWORK = 'homework',
  ACTIVITY = 'activity',
  HYGIENE = 'hygiene',
  CUSTOM = 'custom',
}

export enum ReminderFrequency {
  ONCE = 'once',
  DAILY = 'daily',
  WEEKLY = 'weekly',
  INTERVAL = 'interval',
}

export interface CompletionEntry {
  date: Date;
  completed: boolean;
  completedAt?: Date;
  feedback?: string;
  proofImageUrl?: string;
  verificationStatus?: 'PENDING' | 'VALID' | 'UNCERTAIN' | 'INVALID';
  verificationMetadata?: Record<string, any>;
}

export interface TaskReminderProps {
  childId: string;
  createdBy: string;
  type: ReminderType;
  title: string;
  description?: string;
  icon?: string;
  color?: string;
  frequency: ReminderFrequency;
  times: string[];
  intervalMinutes?: number;
  daysOfWeek: string[];
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  completionHistory: CompletionEntry[];
  isActive: boolean;
  linkedNutritionPlanId?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export class TaskReminderEntity extends Entity<string> {
  private props: TaskReminderProps;

  private constructor(id: string, props: TaskReminderProps) {
    super(id);
    this.props = props;
  }

  static create(props: Omit<TaskReminderProps, 'completionHistory' | 'isActive'>, id?: string): TaskReminderEntity {
    return new TaskReminderEntity(id ?? Entity.generateId(), {
      ...props,
      completionHistory: [],
      isActive: true,
    });
  }

  static reconstitute(id: string, props: TaskReminderProps): TaskReminderEntity {
    return new TaskReminderEntity(id, props);
  }

  get childId() { return this.props.childId; }
  get createdBy() { return this.props.createdBy; }
  get type() { return this.props.type; }
  get title() { return this.props.title; }
  get description() { return this.props.description; }
  get icon() { return this.props.icon; }
  get color() { return this.props.color; }
  get frequency() { return this.props.frequency; }
  get times() { return this.props.times; }
  get intervalMinutes() { return this.props.intervalMinutes; }
  get daysOfWeek() { return this.props.daysOfWeek; }
  get soundEnabled() { return this.props.soundEnabled; }
  get vibrationEnabled() { return this.props.vibrationEnabled; }
  get completionHistory() { return this.props.completionHistory; }
  get isActive() { return this.props.isActive; }
  get linkedNutritionPlanId() { return this.props.linkedNutritionPlanId; }
  get createdAt() { return this.props.createdAt; }
  get updatedAt() { return this.props.updatedAt; }

  update(data: Partial<TaskReminderProps>): void {
    Object.assign(this.props, data);
  }

  deactivate(): void {
    this.props.isActive = false;
  }

  addCompletion(entry: CompletionEntry): number {
    const dateStr = entry.date.toISOString().split('T')[0];
    const idx = this.props.completionHistory.findIndex(
      (h) => h.date.toISOString().split('T')[0] === dateStr,
    );
    if (idx >= 0) {
      this.props.completionHistory[idx] = entry;
      return idx;
    }
    this.props.completionHistory.push(entry);
    return this.props.completionHistory.length - 1;
  }

  setVerification(index: number, status: string, metadata?: Record<string, any>): void {
    if (index >= 0 && index < this.props.completionHistory.length) {
      this.props.completionHistory[index].verificationStatus = status as any;
      if (metadata) this.props.completionHistory[index].verificationMetadata = metadata;
    }
  }
}

/* ─── Repository Interfaces ─── */
export interface INutritionPlanRepository {
  findByChildId(childId: string, activeOnly?: boolean): Promise<NutritionPlanEntity | null>;
  findById(id: string): Promise<NutritionPlanEntity | null>;
  save(entity: NutritionPlanEntity): Promise<NutritionPlanEntity>;
  update(entity: NutritionPlanEntity): Promise<NutritionPlanEntity>;
}

export interface ITaskReminderRepository {
  findByChildId(childId: string, activeOnly?: boolean): Promise<TaskReminderEntity[]>;
  findById(id: string): Promise<TaskReminderEntity | null>;
  save(entity: TaskReminderEntity): Promise<TaskReminderEntity>;
  update(entity: TaskReminderEntity): Promise<TaskReminderEntity>;
}
