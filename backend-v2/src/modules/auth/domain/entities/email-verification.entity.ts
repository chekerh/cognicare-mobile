/**
 * Email Verification Entity - Domain Layer
 */
import { Entity } from '../../../../core/domain/entity.base';
import { ValidationException } from '../../../../core/domain/exceptions';
import * as crypto from 'crypto';

export interface EmailVerificationProps {
  email: string;
  codeHash: string;
  expiresAt: Date;
  createdAt?: Date;
}

export class EmailVerificationEntity extends Entity<string> {
  private _email!: string;
  private _codeHash!: string;
  private _expiresAt!: Date;
  private _createdAt?: Date;

  private constructor(id: string, props: EmailVerificationProps) {
    super(id);
    this._email = props.email;
    this._codeHash = props.codeHash;
    this._expiresAt = props.expiresAt;
    this._createdAt = props.createdAt;
  }

  // Factory method for creating new verification
  static create(email: string, code: string, ttlMinutes: number = 10): EmailVerificationEntity {
    if (!email?.trim()) {
      throw new ValidationException('Email is required');
    }
    if (!code) {
      throw new ValidationException('Code is required');
    }

    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + ttlMinutes * 60 * 1000);

    return new EmailVerificationEntity(Entity.generateId(), {
      email: email.toLowerCase().trim(),
      codeHash,
      expiresAt,
      createdAt: new Date(),
    });
  }

  // Factory for reconstituting from persistence
  static reconstitute(id: string, props: EmailVerificationProps): EmailVerificationEntity {
    return new EmailVerificationEntity(id, props);
  }

  // Getters
  get email(): string { return this._email; }
  get codeHash(): string { return this._codeHash; }
  get expiresAt(): Date { return this._expiresAt; }
  get createdAt(): Date | undefined { return this._createdAt; }

  // Business methods
  isExpired(): boolean {
    return new Date() > this._expiresAt;
  }

  isValid(): boolean {
    return !this.isExpired();
  }

  verifyCode(code: string): boolean {
    const inputHash = crypto.createHash('sha256').update(code).digest('hex');
    return this._codeHash === inputHash && this.isValid();
  }

  // Static helper
  static generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}
