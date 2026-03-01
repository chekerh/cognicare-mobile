/**
 * Base Entity class for all domain entities.
 * Domain entities are plain TypeScript classes with no framework dependencies.
 * They encapsulate business rules and invariants.
 *
 * Two usage patterns:
 * 1. Entity<string> — older entities store their own props, pass id to super(id)
 * 2. Entity<PropsType> — newer entities pass (id) to super, store own props
 */
export abstract class Entity<_T = any> {
  protected readonly _id: string;

  constructor(id: string) {
    this._id = id;
  }

  get id(): string {
    return this._id;
  }

  /**
   * Check equality between entities based on ID.
   */
  equals(entity?: Entity<any>): boolean {
    if (entity === null || entity === undefined) {
      return false;
    }
    if (this === entity) {
      return true;
    }
    return this._id === entity._id;
  }

  /**
   * Generate a new unique ID (24-character hex for MongoDB ObjectId compatibility)
   */
  static generateId(): string {
    const timestamp = Math.floor(Date.now() / 1000)
      .toString(16)
      .padStart(8, "0");
    const randomBytes = Array.from({ length: 16 }, () =>
      Math.floor(Math.random() * 16).toString(16),
    ).join("");
    return timestamp + randomBytes;
  }
}

/**
 * UniqueEntityId value object for entity identifiers.
 */
export class UniqueEntityId {
  private readonly _value: string;

  constructor(id?: string) {
    this._value = id ?? this.generateId();
  }

  get value(): string {
    return this._value;
  }

  private generateId(): string {
    // Simple UUID-like generation for now
    // In production, use proper ObjectId or UUID
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  equals(id?: UniqueEntityId): boolean {
    if (id === null || id === undefined) {
      return false;
    }
    return this._value === id._value;
  }

  toString(): string {
    return this._value;
  }
}
