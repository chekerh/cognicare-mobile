# CogniCare AI Agent Instructions

## Project Architecture

Monorepo with Flutter mobile app (`frontend/`) and NestJS REST API (`backend/`) for cognitive health management. Communication via JWT-authenticated HTTP.

### Backend (NestJS + MongoDB)
- **Entry**: [backend/src/main.ts](../backend/src/main.ts) configures Swagger at `/api`, global prefix `/api/v1`, CORS, validation, compression, Helmet
- **Module structure**: Auth, Users, Health, Mail, Database in [backend/src/app.module.ts](../backend/src/app.module.ts)
- **Global middleware**: `ValidationPipe` (whitelist, transform), `HttpExceptionFilter`, `LoggingInterceptor`, rate limiting (10 req/min)
- **API docs**: Swagger UI at `http://localhost:3000/api` with JWT bearer auth

### Frontend (Flutter)
- **Entry**: [frontend/lib/main.dart](../frontend/lib/main.dart) - Material 3, Provider state, GoRouter navigation
- **Package name**: `cognicare_frontend` (critical for imports)
- **Flutter version**: 3.24.0+ (Dart SDK 3.3.0+ required for intl 0.20.2)
- **State**: Provider pattern in [frontend/lib/providers/](../frontend/lib/providers/)
- **Routing**: Declarative GoRouter in [frontend/lib/utils/router.dart](../frontend/lib/utils/router.dart)
- **API config**: Backend URLs in [frontend/lib/utils/constants.dart](../frontend/lib/utils/constants.dart) - **update `baseUrl` for deployment**
- **i18n**: English, French, Arabic (RTL) via `flutter_localizations`
- **Theme**: Centralized in [frontend/lib/utils/theme.dart](../frontend/lib/utils/theme.dart) - Primary: `#A4D7E1`, Secondary: `#A7E9A4`

## Critical Developer Workflows

### Starting Development
```bash
# Full stack (recommended)
docker-compose up -d

# Backend only (requires MongoDB)
cd backend && npm install && npm run start:dev

# Frontend only
cd frontend && flutter pub get && flutter run
```

### Environment Setup
**Backend**: Create `.env` (no `.env.example` exists):
```env
MONGODB_URI=mongodb://localhost:27017/cognicare
JWT_SECRET=your-secret-key
JWT_EXPIRATION=3600
PORT=3000
CORS_ORIGIN=http://localhost:3000
SENDGRID_API_KEY=your-key  # Required for email verification
MAIL_FROM=verified@yourdomain.com
BCRYPT_ROUNDS=12
```

**Frontend**: Update `AppConstants.baseUrl` in [constants.dart](../frontend/lib/utils/constants.dart) for non-localhost (e.g., host IP for mobile devices)

### Testing & Linting
```bash
# Backend
npm run lint          # ESLint with auto-fix (uses eslint.config.mjs)
npm run test          # Jest unit tests
npm run test:cov      # Coverage report
npm run build         # TypeScript compilation

# Frontend
flutter analyze       # Dart analyzer (uses analysis_options.yaml)
flutter test          # Widget/unit tests
```

**Linting quirks**:
- Backend ESLint uses typescript-eslint with `no-unsafe-assignment` and `no-unsafe-member-access` disabled in [eslint.config.mjs](../backend/eslint.config.mjs)
- Frontend uses `flutter_lints` with strict analysis - **never use** `.withOpacity()` (deprecated), use `.withValues(alpha:)` instead

### CI/CD
GitHub Actions at [.github/workflows/ci-cd.yml](workflows/ci-cd.yml):
- Triggers: pushes to `main`/`develop`
- Jobs: backend tests, Flutter analyze/test, Docker build/push
- Requires secrets: `DOCKER_USERNAME`, `DOCKER_PASSWORD`

## Project-Specific Conventions

### Backend Patterns
1. **DTOs**: Always use `class-validator` + Swagger decorators ([signup.dto.ts](../backend/src/auth/dto/signup.dto.ts)):
   ```typescript
   export class SignupDto {
     @ApiProperty({ example: 'john@example.com' })
     @IsEmail()
     email: string;
   }
   ```

2. **User roles**: Enum `['family', 'doctor', 'volunteer', 'admin']` in [user.schema.ts](../backend/src/users/schemas/user.schema.ts). Admin can **only** be created via direct DB insert (security).

3. **Password handling**: bcrypt with 12 salt rounds ([auth.service.ts](../backend/src/auth/auth.service.ts) line 60)

4. **Email verification flow**: 
   - Two-step signup: 1) `POST /auth/send-verification-code` 2) `POST /auth/signup` with code
   - 6-digit codes hashed in MongoDB collection with TTL index (10min expiry)
   - SendGrid integration required - configure `SENDGRID_API_KEY` and verify sender at SendGrid dashboard

5. **JWT tokens**: Access token (15m), refresh token (7d). Refresh stored hashed in user doc. Password/email changes invalidate refresh tokens.

6. **Error handling**: Custom `HttpExceptionFilter` at [backend/src/common/filters/http-exception.filter.ts](../backend/src/common/filters/http-exception.filter.ts) formats all errors consistently with `statusCode`, `timestamp`, `path`, `method`, `error`, `message`.

### Frontend Patterns
1. **Navigation**: Use `context.go('/route')` from GoRouter, **never** `Navigator.push()`. Routes defined as constants in `AppConstants`.

2. **BuildContext async gaps**: Always capture `ScaffoldMessenger`, `Navigator`, `GoRouter` **before** any `await`:
   ```dart
   onTap: () async {
     final messenger = ScaffoldMessenger.of(context);  // Capture first
     final result = await showDialog(...);            // Then await
     if (mounted) messenger.showSnackBar(...);
   }
   ```

3. **API calls**: Service layer pattern ([auth_service.dart](../frontend/lib/services/auth_service.dart)):
   - Constructor injection for testability: `http.Client`, `FlutterSecureStorage`
   - All endpoints: `AppConstants.baseUrl + AppConstants.<endpoint>`
   - JWT stored via `flutter_secure_storage` with key `AppConstants.jwtTokenKey`

4. **State management**: Provider with `notifyListeners()` after every mutation. Example: [auth_provider.dart](../frontend/lib/providers/auth_provider.dart).

5. **Localization**: Use `AppLocalizations.of(context)!.translate('key')` - supports English, French, Arabic (RTL).

## Integration & Data Flow

### Authentication Flow
1. Frontend → `POST /api/v1/auth/send-verification-code` → SendGrid email sent
2. Frontend → `POST /api/v1/auth/signup` (with code) → Backend validates code from MongoDB
3. Backend returns `{ accessToken, refreshToken, user }`
4. Frontend stores tokens in `flutter_secure_storage`, saves user to `AuthProvider`
5. Authenticated requests add `Authorization: Bearer <token>` header
6. Backend validates via `JwtAuthGuard` + `JwtStrategy` (Passport.js)

### Cross-Component Communication
- **HTTP only**: No direct coupling between frontend/backend
- **API versioning**: All endpoints under `/api/v1` - increment for breaking changes
- **CORS**: Backend allows `CORS_ORIGIN` env var + hardcoded Flutter dev servers (ports 54200-54202) + localhost:8080

### MongoDB Schema Patterns
- Mongoose schemas with `@Schema({ timestamps: true })` for auto `createdAt`/`updatedAt`
- TTL indexes for auto-expiring docs (e.g., [email-verification.schema.ts](../backend/src/auth/schemas/email-verification.schema.ts))
- Unique indexes on `email` field ([user.schema.ts](../backend/src/users/schemas/user.schema.ts))

## Key Files Reference
- **Backend config**: [main.ts](../backend/src/main.ts), [app.module.ts](../backend/src/app.module.ts)
- **Frontend config**: [main.dart](../frontend/lib/main.dart), [constants.dart](../frontend/lib/utils/constants.dart)
- **Auth logic**: [auth.service.ts](../backend/src/auth/auth.service.ts), [auth_provider.dart](../frontend/lib/providers/auth_provider.dart)
- **DB schemas**: [user.schema.ts](../backend/src/users/schemas/user.schema.ts), [email-verification.schema.ts](../backend/src/auth/schemas/email-verification.schema.ts)
- **Docker**: [docker-compose.yml](../docker-compose.yml), [init-mongo.js](../backend/init-mongo.js)
- **CI/CD**: [ci-cd.yml](workflows/ci-cd.yml)

## Common Gotchas
1. **Flutter package name**: `cognicare_frontend` not `frontend` - critical for test imports
2. **Flutter version**: CI/CD uses 3.24.0+ for Dart SDK 3.3.0+ compatibility (intl 0.20.2 requirement)
3. **intl dependency**: Set to `any` in pubspec.yaml - managed by flutter_localizations, pinned to 0.20.2
4. **CORS origins**: Backend allows `http://localhost:3000`, `:8080`, `:54200-54202`, and `CORS_ORIGIN` env var. Update for production.
5. **Mobile device testing**: Change `AppConstants.baseUrl` from `localhost:3000` to host machine IP (e.g., `192.168.1.100:3000`)
6. **SendGrid sender verification**: Email sending fails unless sender verified at https://app.sendgrid.com/settings/sender_auth/senders
7. **MongoDB init**: [init-mongo.js](../backend/init-mongo.js) creates indexes on first Docker start. Admin user must be created manually.
8. **Deprecated APIs**: Never use `.withOpacity()` in Flutter - use `.withValues(alpha:)` instead
9. **BuildContext warnings**: `use_build_context_synchronously` requires capturing context objects before async gaps, even with `mounted` checks
10. **ESLint auto-fix**: Running `npm run lint` applies `--fix` automatically - may reformat code
11. **Port conflicts**: Frontend (8080), Backend (3000), MongoDB (27017) - ensure all available before `docker-compose up`
12. **Swagger auth**: Click "Authorize" in Swagger UI (`/api`), enter JWT token with `Bearer ` prefix to test protected endpoints
