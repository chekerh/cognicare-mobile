# CogniCare Backend v2 - Clean Architecture

## Overview

This is a complete rebuild of the CogniCare backend following **Clean Architecture** principles. The architecture separates concerns into distinct layers, making the codebase more testable, maintainable, and scalable.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Interface Layer                         │
│         (Controllers, WebSocket Gateways, CLI)              │
├─────────────────────────────────────────────────────────────┤
│                    Application Layer                         │
│              (Use Cases, DTOs, Application Services)         │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│    (Entities, Value Objects, Repository Interfaces,         │
│     Domain Services, Domain Exceptions)                      │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                       │
│  (MongoDB Repositories, Mappers, External Services,         │
│   JWT Strategies, Email Services, File Uploads)              │
└─────────────────────────────────────────────────────────────┘
```

### Layer Dependencies (The Dependency Rule)

Dependencies flow **inward only**:
- Interface → Application → Domain
- Infrastructure → Domain (implements interfaces)
- **Domain layer has NO dependencies on other layers**

## Directory Structure

```
backend-v2/
├── src/
│   ├── app/                          # Application bootstrap & config
│   │   ├── app.module.ts             # Root module
│   │   └── health.controller.ts      # Health check endpoint
│   │
│   ├── core/                         # Core building blocks (shared by all modules)
│   │   ├── domain/
│   │   │   ├── entity.base.ts        # Base Entity class
│   │   │   ├── value-object.base.ts  # Base Value Object class
│   │   │   ├── aggregate-root.base.ts# Aggregate Root with domain events
│   │   │   ├── repository.interface.ts # Generic repository interface
│   │   │   └── exceptions.ts         # Domain exception hierarchy
│   │   └── application/
│   │       ├── result.ts             # Result<T,E> monad for error handling
│   │       └── use-case.interface.ts # IUseCase interface
│   │
│   ├── shared/                       # Shared infrastructure
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   ├── roles.guard.ts
│   │   │   └── admin.guard.ts
│   │   └── decorators/
│   │       ├── roles.decorator.ts
│   │       └── public.decorator.ts
│   │
│   ├── infrastructure/               # Cross-cutting infrastructure
│   │   └── database/
│   │       └── database.module.ts    # MongoDB connection
│   │
│   ├── modules/                      # Feature modules
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── email-verification.entity.ts
│   │   │   │   │   └── refresh-token.entity.ts
│   │   │   │   └── repositories/
│   │   │   │       ├── email-verification.repository.interface.ts
│   │   │   │       └── refresh-token.repository.interface.ts
│   │   │   ├── application/
│   │   │   │   ├── dto/
│   │   │   │   │   └── auth.dto.ts
│   │   │   │   └── use-cases/
│   │   │   │       ├── send-verification-code.use-case.ts
│   │   │   │       ├── signup.use-case.ts
│   │   │   │       └── login.use-case.ts
│   │   │   ├── infrastructure/
│   │   │   │   ├── persistence/mongo/
│   │   │   │   │   ├── email-verification.schema.ts
│   │   │   │   │   ├── email-verification.mongo-repository.ts
│   │   │   │   │   ├── refresh-token.schema.ts
│   │   │   │   │   └── refresh-token.mongo-repository.ts
│   │   │   │   ├── mappers/
│   │   │   │   │   ├── email-verification.mapper.ts
│   │   │   │   │   └── refresh-token.mapper.ts
│   │   │   │   └── strategies/
│   │   │   │       └── jwt.strategy.ts
│   │   │   ├── interface/http/
│   │   │   │   └── auth.controller.ts
│   │   │   └── auth.module.ts
│   │   │
│   │   ├── users/                    # Users module (same structure)
│   │   ├── organization/             # Organization module
│   │   └── children/                 # Children module (complete template)
│   │
│   └── main.ts                       # Application entry point
│
├── package.json
├── tsconfig.json
└── README.md
```

## Core Patterns

### 1. Entity Base Class

```typescript
abstract class Entity<T> {
  protected readonly _id: T;
  
  constructor(id: T) {
    this._id = id;
  }
  
  get id(): T { return this._id; }
  
  equals(entity?: Entity<T>): boolean { ... }
  
  static generateId(): string { ... }
}
```

### 2. Repository Interface

```typescript
interface IRepository<T extends Entity<unknown>> {
  findById(id: string): Promise<T | null>;
  findAll(): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<boolean>;
  exists(id: string): Promise<boolean>;
}
```

### 3. Use Case Interface

```typescript
interface IUseCase<Input, Output> {
  execute(input: Input): Promise<Output>;
}
```

### 4. Result Monad

```typescript
type Result<T, E> = Ok<T> | Err<E>;

// Usage in use cases:
async execute(input: Input): Promise<Result<Output, string>> {
  if (invalid) return err('Error message');
  return ok({ data });
}
```

### 5. Dependency Injection via Tokens

```typescript
// Define token in domain layer
export const CHILD_REPOSITORY_TOKEN = Symbol('IChildRepository');

// Bind in module
{
  provide: CHILD_REPOSITORY_TOKEN,
  useClass: ChildMongoRepository,
}

// Inject in use case
constructor(
  @Inject(CHILD_REPOSITORY_TOKEN)
  private readonly childRepo: IChildRepository,
) {}
```

## Module Template: Children

The Children module serves as the complete reference implementation:

### Domain Layer
- **Entity**: `ChildEntity` with business rules (age validation, medical info)
- **Repository Interface**: `IChildRepository` extends `IRepository<ChildEntity>`

### Application Layer
- **DTOs**: Request/response structures
- **Use Cases**: Single-responsibility operations
  - `CreateChildForFamilyUseCase`
  - `CreateChildForSpecialistUseCase`
  - `GetChildrenByFamilyUseCase`
  - `GetChildrenBySpecialistUseCase`
  - `UpdateChildUseCase`

### Infrastructure Layer
- **Schema**: Mongoose schema for MongoDB
- **Mapper**: Converts between domain entity and persistence model
- **Repository**: MongoDB implementation of `IChildRepository`

### Interface Layer
- **Controller**: HTTP endpoints with guards and validation

## Creating a New Module

1. **Domain Layer First**
   ```bash
   mkdir -p src/modules/feature/domain/{entities,repositories}
   ```
   - Create entity with business logic
   - Define repository interface with token

2. **Infrastructure Layer**
   ```bash
   mkdir -p src/modules/feature/infrastructure/{persistence/mongo,mappers}
   ```
   - Create Mongoose schema
   - Create mapper class
   - Implement repository

3. **Application Layer**
   ```bash
   mkdir -p src/modules/feature/application/{dto,use-cases}
   ```
   - Create DTOs
   - Create use cases

4. **Interface Layer**
   ```bash
   mkdir -p src/modules/feature/interface/http
   ```
   - Create controller

5. **Module File**
   - Wire everything together with DI

## Error Handling

### Domain Exceptions
```typescript
throw new InvalidInputException('Field is required');
throw new EntityNotFoundException('Child', id);
throw new BusinessRuleViolationException('Cannot delete active child');
```

### Use Case Results
```typescript
const result = await useCase.execute(input);
if (result.isErr()) {
  throw new BadRequestException(result.error);
}
return result.value;
```

## Testing Strategy

### Unit Tests
- Domain entities: Test business logic in isolation
- Use cases: Mock repository interfaces
- Mappers: Test conversion accuracy

### Integration Tests
- Controllers: Use TestingModule with real database
- Repositories: Test MongoDB operations

### E2E Tests
- Full API flow testing

## Migration from v1

The old MVC structure in `backend/` will be gradually replaced:

1. ✅ Core infrastructure (base classes, guards)
2. ✅ Auth module (email verification, signup, login)
3. ✅ Users module (user entity, repository)
4. ✅ Organization module (org entity, repository)
5. ✅ Children module (complete template)
6. ⏳ Community module
7. ⏳ Marketplace module
8. ⏳ Gamification module
9. ⏳ Remaining 20+ modules...

**Current Stats:** 72 TypeScript files across 54 directories

## Running the Application

```bash
cd cognicare-mobile/backend-v2

# Install dependencies
npm install

# Development
npm run start:dev

# Production build
npm run build
npm run start:prod
```

API available at:
- REST API: `http://localhost:3000/api/v1`
- Swagger Docs: `http://localhost:3000/api`
- Health Check: `http://localhost:3000/api/v1/health`

## Environment Variables

```env
# Database
MONGODB_URI=mongodb://localhost:27017/cognicare

# JWT
JWT_SECRET=your-super-secret-key
JWT_EXPIRATION=3600

# Security
BCRYPT_ROUNDS=12
THROTTLE_TTL=60000
THROTTLE_LIMIT=10

# CORS
CORS_ORIGIN=http://localhost:5173
```
