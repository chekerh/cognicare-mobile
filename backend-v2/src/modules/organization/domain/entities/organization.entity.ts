/**
 * Organization Entity - Domain Layer
 */
import { Entity } from '../../../../core/domain/entity.base';
import { ValidationException } from '../../../../core/domain/exceptions';

export interface OrganizationProps {
  name: string;
  leaderId: string;
  staffIds: string[];
  childIds: string[];
  certificateUrl?: string;
  description?: string;
  address?: string;
  phone?: string;
  email?: string;
  website?: string;
  isApproved: boolean;
  approvedAt?: Date;
  rejectedAt?: Date;
  rejectionReason?: string;
  deletedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export class OrganizationEntity extends Entity<string> {
  private _name!: string;
  private _leaderId!: string;
  private _staffIds!: string[];
  private _childIds!: string[];
  private _certificateUrl?: string;
  private _description?: string;
  private _address?: string;
  private _phone?: string;
  private _email?: string;
  private _website?: string;
  private _isApproved!: boolean;
  private _approvedAt?: Date;
  private _rejectedAt?: Date;
  private _rejectionReason?: string;
  private _deletedAt?: Date;
  private _createdAt?: Date;
  private _updatedAt?: Date;

  private constructor(id: string, props: OrganizationProps) {
    super(id);
    this.assignProps(props);
  }

  private assignProps(props: OrganizationProps): void {
    this._name = props.name;
    this._leaderId = props.leaderId;
    this._staffIds = props.staffIds || [];
    this._childIds = props.childIds || [];
    this._certificateUrl = props.certificateUrl;
    this._description = props.description;
    this._address = props.address;
    this._phone = props.phone;
    this._email = props.email;
    this._website = props.website;
    this._isApproved = props.isApproved;
    this._approvedAt = props.approvedAt;
    this._rejectedAt = props.rejectedAt;
    this._rejectionReason = props.rejectionReason;
    this._deletedAt = props.deletedAt;
    this._createdAt = props.createdAt;
    this._updatedAt = props.updatedAt;
  }

  // Factory method for creating new organization
  static create(props: Omit<OrganizationProps, 'staffIds' | 'childIds' | 'isApproved' | 'createdAt' | 'updatedAt'>): OrganizationEntity {
    if (!props.name?.trim()) {
      throw new ValidationException('Organization name is required');
    }
    if (!props.leaderId) {
      throw new ValidationException('Organization leader ID is required');
    }

    return new OrganizationEntity(Entity.generateId(), {
      ...props,
      name: props.name.trim(),
      staffIds: [],
      childIds: [],
      isApproved: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  // Factory method for reconstituting from persistence
  static reconstitute(id: string, props: OrganizationProps): OrganizationEntity {
    return new OrganizationEntity(id, props);
  }

  // Getters
  get name(): string { return this._name; }
  get leaderId(): string { return this._leaderId; }
  get staffIds(): readonly string[] { return this._staffIds; }
  get childIds(): readonly string[] { return this._childIds; }
  get certificateUrl(): string | undefined { return this._certificateUrl; }
  get description(): string | undefined { return this._description; }
  get address(): string | undefined { return this._address; }
  get phone(): string | undefined { return this._phone; }
  get email(): string | undefined { return this._email; }
  get website(): string | undefined { return this._website; }
  get isApproved(): boolean { return this._isApproved; }
  get approvedAt(): Date | undefined { return this._approvedAt; }
  get rejectedAt(): Date | undefined { return this._rejectedAt; }
  get rejectionReason(): string | undefined { return this._rejectionReason; }
  get deletedAt(): Date | undefined { return this._deletedAt; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  // Business methods
  approve(): void {
    this._isApproved = true;
    this._approvedAt = new Date();
    this._rejectedAt = undefined;
    this._rejectionReason = undefined;
    this._updatedAt = new Date();
  }

  reject(reason: string): void {
    if (!reason?.trim()) {
      throw new ValidationException('Rejection reason is required');
    }
    this._isApproved = false;
    this._rejectedAt = new Date();
    this._rejectionReason = reason.trim();
    this._updatedAt = new Date();
  }

  addStaff(userId: string): void {
    if (!userId) {
      throw new ValidationException('User ID is required');
    }
    if (!this._staffIds.includes(userId)) {
      this._staffIds.push(userId);
      this._updatedAt = new Date();
    }
  }

  removeStaff(userId: string): void {
    const index = this._staffIds.indexOf(userId);
    if (index > -1) {
      this._staffIds.splice(index, 1);
      this._updatedAt = new Date();
    }
  }

  addChild(childId: string): void {
    if (!childId) {
      throw new ValidationException('Child ID is required');
    }
    if (!this._childIds.includes(childId)) {
      this._childIds.push(childId);
      this._updatedAt = new Date();
    }
  }

  removeChild(childId: string): void {
    const index = this._childIds.indexOf(childId);
    if (index > -1) {
      this._childIds.splice(index, 1);
      this._updatedAt = new Date();
    }
  }

  hasStaff(userId: string): boolean {
    return this._staffIds.includes(userId);
  }

  hasChild(childId: string): boolean {
    return this._childIds.includes(childId);
  }

  isLeader(userId: string): boolean {
    return this._leaderId === userId;
  }

  updateDetails(props: {
    name?: string;
    description?: string;
    address?: string;
    phone?: string;
    email?: string;
    website?: string;
  }): void {
    if (props.name !== undefined) this._name = props.name.trim();
    if (props.description !== undefined) this._description = props.description;
    if (props.address !== undefined) this._address = props.address;
    if (props.phone !== undefined) this._phone = props.phone;
    if (props.email !== undefined) this._email = props.email;
    if (props.website !== undefined) this._website = props.website;
    this._updatedAt = new Date();
  }

  softDelete(): void {
    this._deletedAt = new Date();
    this._updatedAt = new Date();
  }
}
