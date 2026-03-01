/**
 * Domain exception base classes.
 * These are used for business rule violations in the domain layer.
 */

export abstract class DomainException extends Error {
  readonly code: string;
  
  constructor(message: string, code: string) {
    super(message);
    this.code = code;
    this.name = this.constructor.name;
  }
}

export class EntityNotFoundException extends DomainException {
  constructor(entityName: string, id: string) {
    super(`${entityName} with ID ${id} not found`, 'ENTITY_NOT_FOUND');
  }
}

export class InvalidEntityStateException extends DomainException {
  constructor(message: string) {
    super(message, 'INVALID_ENTITY_STATE');
  }
}

export class BusinessRuleViolationException extends DomainException {
  constructor(message: string) {
    super(message, 'BUSINESS_RULE_VIOLATION');
  }
}

export class UnauthorizedAccessException extends DomainException {
  constructor(message: string = 'Unauthorized access') {
    super(message, 'UNAUTHORIZED_ACCESS');
  }
}

export class ForbiddenAccessException extends DomainException {
  constructor(message: string = 'Access forbidden') {
    super(message, 'FORBIDDEN_ACCESS');
  }
}

export class ValidationException extends DomainException {
  readonly errors: Record<string, string[]>;

  constructor(errors: Record<string, string[]> | string) {
    super(typeof errors === 'string' ? errors : 'Validation failed', 'VALIDATION_ERROR');
    this.errors = typeof errors === 'string' ? { message: [errors] } : errors;
  }
}

export class ConflictException extends DomainException {
  constructor(message: string) {
    super(message, 'CONFLICT');
  }
}
