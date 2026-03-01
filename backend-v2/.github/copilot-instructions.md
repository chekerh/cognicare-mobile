# CogniCare Backend v2 - Clean Architecture AI Agent Instructions

## Critical Context

**This is a complete rewrite** of the legacy backend (`../backend/`) using Clean Architecture principles. The old MVC-style backend continues to run in production while v2 is being built incrementally.

**Status**: Foundation complete (4 modules). 20+ modules to migrate.  
**Reference Implementation**: `src/modules/children/` (complete template for all modules)

## Architecture Layers (The Dependency Rule)

Dependencies flow **inward only**: Interface → Application → Domain ← Infrastructure

```
src/
  core/                          # Shared building blocks
    domain/
      entity.base.ts              # Entity<T> with generateId()
      repository.interface.ts     # IRepository<T> + IExtendedRepository<T>
      exceptions.ts               # ValidationException, EntityNotFoundException, etc.
    application/
      result.ts                   # Result<T,E> monad (ok/err helpers)
      use-case.interface.ts       # IUseCase<Input, Output>
  
  modules/<feature>/
    domain/
      entities/*.entity.ts        # Plain TypeScript classes, NO decorators
      repositories/*.interface.ts # Contracts with DI tokens (Symbol)
    application/
      dto/*.dto.ts                # API contracts (class-validator decorators)
      use-cases/*.use-case.ts     # Single-responsibility business logic
    infrastructure/
      persistence/mongo/
        *.schema.ts               # Mongoose schemas (@Prop, @Schema)
        *.mongo-repository.ts     # IRepository implementations
      mappers/*.mapper.ts         # toDomain() / toPersistence()
    interface/http/
      *.controller.ts             # NestJS controllers
    <feature>.module.ts           # DI bindings
```

## Core Patterns (Non-Negotiable)

### 1. Entity Pattern
```typescript
export class ChildEntity extends Entity<string> {
  private _fullName!: string;  // Definite assignment (! for strict mode)
  
  private constructor(id: string, props: ChildProps) {
    super(id);
    this._fullName = props.fullName;
  }
  
  // Factory for new entities
  static create(props: Omit<ChildProps, 'createdAt'>): ChildEntity {
    if (!props.fullName?.trim()) {
      throw new ValidationException('Full name required');
    }
    return new ChildEntity(Entity.generateId(), {
      ...props,
      createdAt: new Date(),
    });
  }
  
  // Factory for reconstitution from DB
  static reconstitute(id: string, props: ChildProps): ChildEntity {
    return new ChildEntity(id, props);
  }
  
  get fullName(): string { return this._fullName; }
}
```

### 2. Repository Pattern (Interface in Domain, Implementation in Infrastructure)
```typescript
// domain/repositories/child.repository.interface.ts
export const CHILD_REPOSITORY_TOKEN = Symbol('IChildRepository');

export interface IChildRepository extends IRepository<ChildEntity> {
  findByParentId(parentId: string): Promise<ChildEntity[]>;
}

// infrastructure/persistence/mongo/child.mongo-repository.ts
@Injectable()
export class ChildMongoRepository implements IChildRepository {
  constructor(@InjectModel(ChildMongoSchema.name) private model: Model<ChildDocument>) {}
  
  async findByParentId(parentId: string): Promise<ChildEntity[]> {
    const docs = await this.model.find({ parentId: new Types.ObjectId(parentId) }).exec();
    return docs.map(ChildMapper.toDomain);
  }
}

// Module DI binding
{
  provide: CHILD_REPOSITORY_TOKEN,
  useClass: ChildMongoRepository,
}
```

### 3. Use Case Pattern (Business Logic Orchestration)
```typescript
@Injectable()
export class CreateChildForFamilyUseCase {
  constructor(
    @Inject(CHILD_REPOSITORY_TOKEN)
    private readonly childRepo: IChildRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepo: IUserRepository,
  ) {}
  
  async execute(input: CreateChildForFamilyInput): Promise<Result<ChildOutputDto, Error>> {
    // 1. Validate authorization
    if (input.requesterId !== input.familyId) {
      return Result.fail(new ForbiddenAccessException('Cannot add to other profiles'));
    }
    
    // 2. Verify preconditions
    const family = await this.userRepo.findById(input.familyId);
    if (!family) return Result.fail(new EntityNotFoundException('User', input.familyId));
    
    // 3. Execute domain logic
    const child = ChildEntity.create({ ...input.childData, parentId: input.familyId });
    
    // 4. Persist
    const saved = await this.childRepo.save(child);
    
    return Result.ok(ChildMapper.toDto(saved));
  }
}
```

### 4. Result Monad (Explicit Error Handling)
```typescript
// Use cases return Result<T, E> instead of throwing
import { ok, err } from '@/core/application';

async execute(input: Input): Promise<Result<Output, string>> {
  if (invalid) return err('Validation failed');
  return ok({ data });
}

// Controllers unwrap results
const result = await useCase.execute(input);
if (result.isErr()) {
  throw new BadRequestException(result.error);
}
return result.value;
```

### 5. Mapper Pattern (Domain ↔ Persistence Conversion)
```typescript
export class ChildMapper {
  static toDomain(doc: ChildDocument): ChildEntity {
    return ChildEntity.reconstitute(doc._id.toString(), {
      fullName: doc.fullName,
      dateOfBirth: doc.dateOfBirth,
      parentId: doc.parentId.toString(),  // ObjectId → string
    });
  }
  
  static toPersistence(entity: ChildEntity): Record<string, unknown> {
    return {
      fullName: entity.fullName,
      parentId: new Types.ObjectId(entity.parentId),  // string → ObjectId
    };
  }
}
```

## ValidationException Pattern (String or Object)
```typescript
// Domain exceptions accept string OR object
throw new ValidationException('Simple message');
// OR
throw new ValidationException({ email: ['Invalid format'], password: ['Too short'] });

// Both work due to constructor overload:
constructor(errors: Record<string, string[]> | string) {
  super(typeof errors === 'string' ? errors : 'Validation failed', 'VALIDATION_ERROR');
  this.errors = typeof errors === 'string' ? { message: [errors] } : errors;
}
```

## Module Template Workflow (Copy from Children Module)

1. **Domain Layer** (`domain/`)
   - Create entity: `<Feature>Entity extends Entity<string>`
   - Define repository interface: `I<Feature>Repository extends IRepository<T>`
   - Export token: `export const <FEATURE>_REPOSITORY_TOKEN = Symbol(...)`

2. **Infrastructure Layer** (`infrastructure/`)
   - Mongoose schema: `<Feature>MongoSchema` with `@Schema()` decorator
   - Mapper: `toDomain()` / `toPersistence()` static methods
   - Repository: Implement interface, inject `Model<Document>`

3. **Application Layer** (`application/`)
   - DTOs: Request/response with class-validator decorators
   - Use cases: Single-purpose classes with `execute()` method

4. **Interface Layer** (`interface/http/`)
   - Controller: Inject use cases, call `execute()`, unwrap results

5. **Module** (`<feature>.module.ts`)
   - Import dependencies: `forwardRef()` if circular
   - Bind repository: `{ provide: TOKEN, useClass: Implementation }`
   - Register use cases in `providers`

## Critical Anti-Patterns to Avoid

❌ **Database calls in use cases** → Inject repository interfaces  
❌ **Framework decorators in domain entities** → Plain TypeScript only  
❌ **Throwing exceptions from use cases** → Return `Result<T, E>`  
❌ **Direct ObjectId in domain entities** → Always use string IDs  
❌ **Circular imports** → Use `forwardRef()` in modules  
❌ **Missing validation in entity factory** → Validate in `create()` method

## Development Workflows

### Build & Run
```bash
npm run build           # TypeScript compilation
npm run start:dev       # Watch mode (port 3000)
npm run lint            # ESLint
```

### Testing (Not yet implemented)
```bash
npm run test            # Jest unit tests
npm run test:e2e        # End-to-end tests
```

### Swagger Docs
http://localhost:3000/api  
Click "Authorize" → Enter `Bearer <jwt-token>` from login response

### Cross-Module Dependencies
```typescript
// Use forwardRef() to prevent circular dependency errors
import { forwardRef } from '@nestjs/common';

@Module({
  imports: [
    forwardRef(() => UsersModule),
    forwardRef(() => OrganizationModule),
  ],
})
```

## Key Differences from Legacy Backend (`../backend/`)

| Aspect | Legacy (v1) | Clean Architecture (v2) |
|--------|-------------|------------------------|
| **Services** | Business logic + DB calls | Use cases (no DB) + Repositories |
| **Entities** | Mongoose schemas | Plain classes + Separate schemas |
| **Error Handling** | Exceptions everywhere | Result monad |
| **Testing** | Hard (MongoDB required) | Easy (mock repositories) |
| **Dependencies** | Services depend on Mongoose | Domain has zero framework deps |

## Environment Variables
```env
MONGODB_URI=mongodb://localhost:27017/cognicare
JWT_SECRET=your-secret
JWT_EXPIRATION=3600        # Seconds (number, not string with 's')
BCRYPT_ROUNDS=12
```

**Critical**: `JWT_EXPIRATION` must be a number (seconds), not `'3600s'` (causes type error).

## Migration Strategy

1. **Use Children module as template** - Copy structure, rename classes
2. **Create domain entities first** - No dependencies, easiest to test
3. **Define repository interfaces** - Contracts before implementations
4. **Implement infrastructure** - Schemas, mappers, repositories
5. **Build use cases** - One feature at a time
6. **Wire up controllers** - Last step, thin layer

## Common Build Errors & Fixes

**`Cannot find module 'X' or its corresponding type declarations`**  
→ Fix relative imports (use `../../` not `@/` in some places)

**`Type 'string' not assignable to 'number' for expiresIn`**  
→ `parseInt(configService.get<string>('JWT_EXPIRATION') || '3600', 10)`

**`Module '"X"' has no exported member 'Y'`**  
→ Check `index.ts` barrel exports, ensure all exports are present

**`Property 'X' is used before being assigned`**  
→ Use definite assignment: `private _name!: string;`

## Next Steps for AI Agents

- Migrate remaining 20+ modules from `../backend/src/` using Children as template
- Add unit tests for domain entities (no mocks needed)
- Add integration tests for repositories (test database)
- Implement refresh token rotation (auth module TODO)
- Add domain events to AggregateRoot (currently unused)
