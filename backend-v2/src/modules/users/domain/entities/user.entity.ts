/**
 * User Entity - Domain Layer
 */
import { Entity, UniqueEntityId } from '@/core/domain';
import { InvalidEntityStateException } from '@/core/domain';

export type UserRole = 
  | 'family' 
  | 'doctor' 
  | 'volunteer' 
  | 'admin' 
  | 'organization_leader'
  | 'psychologist'
  | 'speech_therapist'
  | 'occupational_therapist'
  | 'other';

export interface UserProps {
  email: string;
  passwordHash: string;
  role: UserRole;
  firstName?: string;
  lastName?: string;
  phone?: string;
  profileImageUrl?: string;
  organizationId?: string;
  isEmailVerified: boolean;
  blockedUserIds?: string[];
  deletedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export class UserEntity extends Entity<string> {
  private props: UserProps;

  private constructor(id: string, props: UserProps) {
    super(id);
    this.props = props;
  }

  // ── Factory Methods ──

  static create(props: UserProps, id?: string): UserEntity {
    UserEntity.validateProps(props);
    return new UserEntity(id ?? new UniqueEntityId().value, {
      ...props,
      blockedUserIds: props.blockedUserIds ?? [],
      isEmailVerified: props.isEmailVerified ?? false,
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: UserProps): UserEntity {
    return new UserEntity(id, props);
  }

  // ── Validation ──

  private static validateProps(props: UserProps): void {
    if (!props.email || !props.email.includes('@')) {
      throw new InvalidEntityStateException('Valid email is required');
    }
    if (!props.passwordHash) {
      throw new InvalidEntityStateException('Password hash is required');
    }
    const validRoles: UserRole[] = [
      'family', 'doctor', 'volunteer', 'admin', 'organization_leader',
      'psychologist', 'speech_therapist', 'occupational_therapist', 'other'
    ];
    if (!validRoles.includes(props.role)) {
      throw new InvalidEntityStateException('Invalid role');
    }
  }

  // ── Getters ──

  get email(): string { return this.props.email; }
  get passwordHash(): string { return this.props.passwordHash; }
  get role(): UserRole { return this.props.role; }
  get firstName(): string | undefined { return this.props.firstName; }
  get lastName(): string | undefined { return this.props.lastName; }
  get fullName(): string {
    const parts = [this.props.firstName, this.props.lastName].filter(Boolean);
    return parts.join(' ') || this.props.email;
  }
  get phone(): string | undefined { return this.props.phone; }
  get profileImageUrl(): string | undefined { return this.props.profileImageUrl; }
  get organizationId(): string | undefined { return this.props.organizationId; }
  get isEmailVerified(): boolean { return this.props.isEmailVerified; }
  get blockedUserIds(): string[] { return this.props.blockedUserIds ?? []; }
  get deletedAt(): Date | undefined { return this.props.deletedAt; }
  get createdAt(): Date | undefined { return this.props.createdAt; }
  get updatedAt(): Date | undefined { return this.props.updatedAt; }
  get isDeleted(): boolean { return !!this.props.deletedAt; }

  get isSpecialist(): boolean {
    return ['psychologist', 'speech_therapist', 'occupational_therapist', 'doctor', 'volunteer', 'other'].includes(this.role);
  }

  get isAdmin(): boolean {
    return this.role === 'admin';
  }

  get isOrganizationLeader(): boolean {
    return this.role === 'organization_leader';
  }

  // ── Business Methods ──

  updateProfile(data: Partial<Pick<UserProps, 'firstName' | 'lastName' | 'phone' | 'profileImageUrl'>>): void {
    if (data.firstName !== undefined) this.props.firstName = data.firstName.trim();
    if (data.lastName !== undefined) this.props.lastName = data.lastName.trim();
    if (data.phone !== undefined) this.props.phone = data.phone.trim();
    if (data.profileImageUrl !== undefined) this.props.profileImageUrl = data.profileImageUrl;
    this.props.updatedAt = new Date();
  }

  updatePasswordHash(hash: string): void {
    this.props.passwordHash = hash;
    this.props.updatedAt = new Date();
  }

  verifyEmail(): void {
    this.props.isEmailVerified = true;
    this.props.updatedAt = new Date();
  }

  assignToOrganization(organizationId: string): void {
    this.props.organizationId = organizationId;
    this.props.updatedAt = new Date();
  }

  removeFromOrganization(): void {
    this.props.organizationId = undefined;
    this.props.updatedAt = new Date();
  }

  blockUser(userId: string): void {
    if (userId === this.id) {
      throw new InvalidEntityStateException('Cannot block yourself');
    }
    if (!this.props.blockedUserIds) {
      this.props.blockedUserIds = [];
    }
    if (!this.props.blockedUserIds.includes(userId)) {
      this.props.blockedUserIds.push(userId);
      this.props.updatedAt = new Date();
    }
  }

  unblockUser(userId: string): void {
    if (this.props.blockedUserIds) {
      this.props.blockedUserIds = this.props.blockedUserIds.filter(id => id !== userId);
      this.props.updatedAt = new Date();
    }
  }

  softDelete(): void {
    this.props.deletedAt = new Date();
    this.props.updatedAt = new Date();
  }

  toObject(): UserProps & { id: string } {
    return {
      id: this.id,
      ...this.props,
    };
  }
}
