import { Entity } from "@/core/domain";

/* ─── VolunteerDocument (value object) ─── */
export interface VolunteerDocProps {
  type: "id" | "certificate" | "other";
  url: string;
  publicId?: string;
  fileName?: string;
  mimeType?: string;
  uploadedAt: Date;
}

/* ─── VolunteerApplicationEntity ─── */
export interface VolunteerApplicationProps {
  userId: string;
  status: "pending" | "approved" | "denied";
  careProviderType?: string;
  specialty?: string;
  organizationName?: string;
  organizationRole?: string;
  documents: VolunteerDocProps[];
  deniedReason?: string;
  reviewedBy?: string;
  reviewedAt?: Date;
  denialNotificationSent?: boolean;
  trainingCertified?: boolean;
  trainingCertifiedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export class VolunteerApplicationEntity extends Entity<string> {
  private props: VolunteerApplicationProps;

  private constructor(id: string, props: VolunteerApplicationProps) {
    super(id);
    this.props = props;
  }

  static create(userId: string): VolunteerApplicationEntity {
    return new VolunteerApplicationEntity(Entity.generateId(), {
      userId,
      status: "pending",
      documents: [],
    });
  }

  static reconstitute(
    id: string,
    props: VolunteerApplicationProps,
  ): VolunteerApplicationEntity {
    return new VolunteerApplicationEntity(id, props);
  }

  get userId() {
    return this.props.userId;
  }
  get status() {
    return this.props.status;
  }
  get careProviderType() {
    return this.props.careProviderType;
  }
  get specialty() {
    return this.props.specialty;
  }
  get organizationName() {
    return this.props.organizationName;
  }
  get organizationRole() {
    return this.props.organizationRole;
  }
  get documents() {
    return this.props.documents;
  }
  get deniedReason() {
    return this.props.deniedReason;
  }
  get reviewedBy() {
    return this.props.reviewedBy;
  }
  get reviewedAt() {
    return this.props.reviewedAt;
  }
  get trainingCertified() {
    return this.props.trainingCertified ?? false;
  }
  get trainingCertifiedAt() {
    return this.props.trainingCertifiedAt;
  }
  get denialNotificationSent() {
    return this.props.denialNotificationSent ?? false;
  }
  get profileComplete() {
    return this.props.documents.length >= 1;
  }
  get createdAt() {
    return this.props.createdAt;
  }
  get updatedAt() {
    return this.props.updatedAt;
  }

  updateProfile(dto: {
    careProviderType?: string;
    specialty?: string;
    organizationName?: string;
    organizationRole?: string;
  }): void {
    if (this.props.status !== "pending")
      throw new Error("Cannot update after review");
    if (dto.careProviderType !== undefined)
      this.props.careProviderType = dto.careProviderType;
    if (dto.specialty !== undefined) this.props.specialty = dto.specialty;
    if (dto.organizationName !== undefined)
      this.props.organizationName = dto.organizationName;
    if (dto.organizationRole !== undefined)
      this.props.organizationRole = dto.organizationRole;
  }

  addDocument(doc: VolunteerDocProps): void {
    if (this.props.status !== "pending")
      throw new Error("Cannot add documents after review");
    this.props.documents.push(doc);
  }

  removeDocument(index: number): VolunteerDocProps {
    if (this.props.status !== "pending")
      throw new Error("Cannot remove documents after review");
    if (index < 0 || index >= this.props.documents.length)
      throw new Error("Invalid document index");
    return this.props.documents.splice(index, 1)[0];
  }

  approve(reviewerId: string): void {
    this.props.status = "approved";
    this.props.reviewedBy = reviewerId;
    this.props.reviewedAt = new Date();
  }

  deny(reviewerId: string, reason?: string): void {
    this.props.status = "denied";
    this.props.reviewedBy = reviewerId;
    this.props.reviewedAt = new Date();
    this.props.deniedReason = reason;
  }

  certifyTraining(): void {
    this.props.trainingCertified = true;
    this.props.trainingCertifiedAt = new Date();
  }
}

/* ─── VolunteerTaskEntity ─── */
export interface VolunteerTaskProps {
  assignedBy: string;
  volunteerId: string;
  title: string;
  description: string;
  status: string;
  dueDate?: Date;
  completedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export class VolunteerTaskEntity extends Entity<string> {
  private props: VolunteerTaskProps;

  private constructor(id: string, props: VolunteerTaskProps) {
    super(id);
    this.props = props;
  }

  static create(
    props: Omit<VolunteerTaskProps, "status" | "createdAt" | "updatedAt">,
  ): VolunteerTaskEntity {
    return new VolunteerTaskEntity(Entity.generateId(), {
      ...props,
      status: "pending",
    });
  }

  static reconstitute(
    id: string,
    props: VolunteerTaskProps,
  ): VolunteerTaskEntity {
    return new VolunteerTaskEntity(id, props);
  }

  get assignedBy() {
    return this.props.assignedBy;
  }
  get volunteerId() {
    return this.props.volunteerId;
  }
  get title() {
    return this.props.title;
  }
  get description() {
    return this.props.description;
  }
  get status() {
    return this.props.status;
  }
  get dueDate() {
    return this.props.dueDate;
  }
  get completedAt() {
    return this.props.completedAt;
  }
  get createdAt() {
    return this.props.createdAt;
  }
  get updatedAt() {
    return this.props.updatedAt;
  }
}
