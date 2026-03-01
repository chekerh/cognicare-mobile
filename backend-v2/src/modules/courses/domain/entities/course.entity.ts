import { Entity } from "../../../../core/entity.base";

/* ─── CourseEntity ─── */
export interface CourseProps {
  title: string;
  description?: string;
  slug: string;
  isQualificationCourse: boolean;
  startDate?: Date;
  endDate?: Date;
  courseType?: string;
  price?: string;
  location?: string;
  enrollmentLink?: string;
  certification?: string;
  targetAudience?: string;
  prerequisites?: string;
  sourceUrl?: string;
  createdAt?: Date;
}

export class CourseEntity extends Entity {
  private props: CourseProps;
  private constructor(props: CourseProps, id: string) {
    super(id);
    this.props = props;
  }
  static create(props: Omit<CourseProps, "createdAt">): CourseEntity {
    return new CourseEntity(
      { ...props, createdAt: new Date() },
      Entity.generateId(),
    );
  }
  static reconstitute(id: string, props: CourseProps): CourseEntity {
    return new CourseEntity(props, id);
  }
  get title() {
    return this.props.title;
  }
  get description() {
    return this.props.description;
  }
  get slug() {
    return this.props.slug;
  }
  get isQualificationCourse() {
    return this.props.isQualificationCourse;
  }
  get startDate() {
    return this.props.startDate;
  }
  get endDate() {
    return this.props.endDate;
  }
  get courseType() {
    return this.props.courseType;
  }
  get price() {
    return this.props.price;
  }
  get location() {
    return this.props.location;
  }
  get enrollmentLink() {
    return this.props.enrollmentLink;
  }
  get certification() {
    return this.props.certification;
  }
  get targetAudience() {
    return this.props.targetAudience;
  }
  get prerequisites() {
    return this.props.prerequisites;
  }
}

/* ─── CourseEnrollmentEntity ─── */
export interface CourseEnrollmentProps {
  userId: string;
  courseId: string;
  status: "enrolled" | "in_progress" | "completed";
  progressPercent: number;
  completedAt?: Date;
  updatedAt?: Date;
}

export class CourseEnrollmentEntity extends Entity {
  private props: CourseEnrollmentProps;
  private constructor(props: CourseEnrollmentProps, id: string) {
    super(id);
    this.props = props;
  }
  static create(userId: string, courseId: string): CourseEnrollmentEntity {
    return new CourseEnrollmentEntity(
      { userId, courseId, status: "enrolled", progressPercent: 0 },
      Entity.generateId(),
    );
  }
  static reconstitute(
    id: string,
    props: CourseEnrollmentProps,
  ): CourseEnrollmentEntity {
    return new CourseEnrollmentEntity(props, id);
  }
  get userId() {
    return this.props.userId;
  }
  get courseId() {
    return this.props.courseId;
  }
  get status() {
    return this.props.status;
  }
  get progressPercent() {
    return this.props.progressPercent;
  }
  get completedAt() {
    return this.props.completedAt;
  }

  updateProgress(percent: number): void {
    this.props.progressPercent = Math.min(100, Math.max(0, percent));
    if (this.props.progressPercent >= 100) {
      this.props.status = "completed";
      this.props.completedAt = new Date();
    } else {
      this.props.status = "in_progress";
    }
  }
}
