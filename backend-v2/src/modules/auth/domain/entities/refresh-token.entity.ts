/**
 * Refresh Token Entity - Domain Layer
 */
import { Entity } from '../../../../core/domain/entity.base';
import { ValidationException } from '../../../../core/domain/exceptions';
import * as crypto from 'crypto';

export interface RefreshTokenProps {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  deviceInfo?: string;
  createdAt?: Date;
}

export class RefreshTokenEntity extends Entity<string> {
  private _userId!: string;
  private _tokenHash!: string;
  private _expiresAt!: Date;
  private _deviceInfo?: string;
  private _createdAt?: Date;

  private constructor(id: string, props: RefreshTokenProps) {
    super(id);
    this._userId = props.userId;
    this._tokenHash = props.tokenHash;
    this._expiresAt = props.expiresAt;
    this._deviceInfo = props.deviceInfo;
    this._createdAt = props.createdAt;
  }

  static create(userId: string, token: string, ttlDays: number = 7, deviceInfo?: string): RefreshTokenEntity {
    if (!userId) {
      throw new ValidationException('User ID is required');
    }
    if (!token) {
      throw new ValidationException('Token is required');
    }

    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const expiresAt = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000);

    return new RefreshTokenEntity(Entity.generateId(), {
      userId,
      tokenHash,
      expiresAt,
      deviceInfo,
      createdAt: new Date(),
    });
  }

  static reconstitute(id: string, props: RefreshTokenProps): RefreshTokenEntity {
    return new RefreshTokenEntity(id, props);
  }

  // Getters
  get userId(): string { return this._userId; }
  get tokenHash(): string { return this._tokenHash; }
  get expiresAt(): Date { return this._expiresAt; }
  get deviceInfo(): string | undefined { return this._deviceInfo; }
  get createdAt(): Date | undefined { return this._createdAt; }

  // Business methods
  isExpired(): boolean {
    return new Date() > this._expiresAt;
  }

  isValid(): boolean {
    return !this.isExpired();
  }

  verifyToken(token: string): boolean {
    const inputHash = crypto.createHash('sha256').update(token).digest('hex');
    return this._tokenHash === inputHash && this.isValid();
  }

  // Static helpers
  static generateToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }
}
