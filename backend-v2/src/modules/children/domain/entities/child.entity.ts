/**
 * Child Entity - Domain Layer
 * 
 * This is a pure domain entity with NO framework dependencies.
 * It encapsulates business rules and invariants for a Child.
 */
import { Entity, UniqueEntityId } from '@/core/domain';
import { InvalidEntityStateException } from '@/core/domain';

export type Gender = 'male' | 'female' | 'other';

export interface ChildProps {
  fullName: string;
  dateOfBirth: Date;
  gender: Gender;
  diagnosis?: string;
  medicalHistory?: string;
  allergies?: string;
  medications?: string;
  notes?: string;
  parentId?: string;
  organizationId?: string;
  specialistId?: string;
  addedByOrganizationId?: string;
  addedBySpecialistId?: string;
  lastModifiedBy?: string;
  deletedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export class ChildEntity extends Entity<string> {
  private props: ChildProps;

  private constructor(id: string, props: ChildProps) {
    super(id);
    this.props = props;
  }

  // ── Factory Methods ──

  /**
   * Create a new Child entity with validation.
   */
  static create(props: ChildProps, id?: string): ChildEntity {
    ChildEntity.validateProps(props);
    return new ChildEntity(id ?? new UniqueEntityId().value, {
      ...props,
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  /**
   * Reconstitute a Child entity from persistence (no validation needed).
   */
  static reconstitute(id: string, props: ChildProps): ChildEntity {
    return new ChildEntity(id, props);
  }

  // ── Validation ──

  private static validateProps(props: ChildProps): void {
    if (!props.fullName || props.fullName.trim().length === 0) {
      throw new InvalidEntityStateException('Child full name is required');
    }
    if (props.fullName.trim().length > 200) {
      throw new InvalidEntityStateException('Child full name must be 200 characters or less');
    }
    if (!props.dateOfBirth) {
      throw new InvalidEntityStateException('Child date of birth is required');
    }
    if (props.dateOfBirth > new Date()) {
      throw new InvalidEntityStateException('Child date of birth cannot be in the future');
    }
    if (!['male', 'female', 'other'].includes(props.gender)) {
      throw new InvalidEntityStateException('Invalid gender value');
    }
    // A child must belong to either a parent OR a specialist (not both, not neither when creating)
    // But for existing records, this rule may be relaxed based on migration logic
  }

  // ── Getters ──

  get fullName(): string {
    return this.props.fullName;
  }

  get dateOfBirth(): Date {
    return this.props.dateOfBirth;
  }

  get gender(): Gender {
    return this.props.gender;
  }

  get diagnosis(): string | undefined {
    return this.props.diagnosis;
  }

  get medicalHistory(): string | undefined {
    return this.props.medicalHistory;
  }

  get allergies(): string | undefined {
    return this.props.allergies;
  }

  get medications(): string | undefined {
    return this.props.medications;
  }

  get notes(): string | undefined {
    return this.props.notes;
  }

  get parentId(): string | undefined {
    return this.props.parentId;
  }

  get organizationId(): string | undefined {
    return this.props.organizationId;
  }

  get specialistId(): string | undefined {
    return this.props.specialistId;
  }

  get addedByOrganizationId(): string | undefined {
    return this.props.addedByOrganizationId;
  }

  get addedBySpecialistId(): string | undefined {
    return this.props.addedBySpecialistId;
  }

  get lastModifiedBy(): string | undefined {
    return this.props.lastModifiedBy;
  }

  get deletedAt(): Date | undefined {
    return this.props.deletedAt;
  }

  get createdAt(): Date | undefined {
    return this.props.createdAt;
  }

  get updatedAt(): Date | undefined {
    return this.props.updatedAt;
  }

  get isDeleted(): boolean {
    return !!this.props.deletedAt;
  }

  get age(): number {
    const today = new Date();
    const birth = this.props.dateOfBirth;
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  // ── Business Methods ──

  /**
   * Update child information.
   */
  update(props: Partial<ChildProps>, modifiedBy: string): void {
    if (props.fullName !== undefined) {
      if (!props.fullName.trim()) {
        throw new InvalidEntityStateException('Child full name cannot be empty');
      }
      this.props.fullName = props.fullName.trim();
    }
    if (props.dateOfBirth !== undefined) {
      if (props.dateOfBirth > new Date()) {
        throw new InvalidEntityStateException('Date of birth cannot be in the future');
      }
      this.props.dateOfBirth = props.dateOfBirth;
    }
    if (props.gender !== undefined) {
      this.props.gender = props.gender;
    }
    if (props.diagnosis !== undefined) {
      this.props.diagnosis = props.diagnosis?.trim();
    }
    if (props.medicalHistory !== undefined) {
      this.props.medicalHistory = props.medicalHistory?.trim();
    }
    if (props.allergies !== undefined) {
      this.props.allergies = props.allergies?.trim();
    }
    if (props.medications !== undefined) {
      this.props.medications = props.medications?.trim();
    }
    if (props.notes !== undefined) {
      this.props.notes = props.notes?.trim();
    }
    
    this.props.lastModifiedBy = modifiedBy;
    this.props.updatedAt = new Date();
  }

  /**
   * Soft delete the child.
   */
  softDelete(): void {
    if (this.props.deletedAt) {
      throw new InvalidEntityStateException('Child is already deleted');
    }
    this.props.deletedAt = new Date();
    this.props.updatedAt = new Date();
  }

  /**
   * Restore a soft-deleted child.
   */
  restore(): void {
    if (!this.props.deletedAt) {
      throw new InvalidEntityStateException('Child is not deleted');
    }
    this.props.deletedAt = undefined;
    this.props.updatedAt = new Date();
  }

  /**
   * Assign child to an organization.
   */
  assignToOrganization(organizationId: string, modifiedBy: string): void {
    this.props.organizationId = organizationId;
    this.props.lastModifiedBy = modifiedBy;
    this.props.updatedAt = new Date();
  }

  /**
   * Export entity to plain object (for serialization).
   */
  toObject(): ChildProps & { id: string } {
    return {
      id: this.id,
      ...this.props,
    };
  }
}
