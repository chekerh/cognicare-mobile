# CogniCare AI Agent Instructions

## Project Architecture

This is a **monorepo** with a Flutter mobile app (`frontend/`) and NestJS REST API (`backend/`), designed for cognitive health management. Communication is via JWT-authenticated HTTP requests.

### Backend (NestJS + MongoDB)
- **Entry**: [backend/src/main.ts](../backend/src/main.ts) - Configures Swagger at `/api`, global prefix `/api/v1`, CORS, validation, compression, Helmet
- **Modules**: Auth, Health, Database - follow NestJS module pattern in [backend/src/app.module.ts](../backend/src/app.module.ts)
- **API Docs**: Auto-generated Swagger at `http://localhost:3000/api` with JWT bearer auth support
- **Global Config**: 
  - All routes prefixed with `/api/v1`
  - Global `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`
  - Global `HttpExceptionFilter` and `LoggingInterceptor` in [backend/src/common/](../backend/src/common/)
  - Rate limiting: 10 requests/minute via `@nestjs/throttler`

### Frontend (Flutter)
- **Entry**: [frontend/lib/main.dart](../frontend/lib/main.dart) - Uses Provider for state, GoRouter for navigation, Material 3
- **State**: Provider pattern - see [frontend/lib/providers/auth_provider.dart](../frontend/lib/providers/auth_provider.dart)
- **Routing**: Declarative with `go_router` in [frontend/lib/utils/router.dart](../frontend/lib/utils/router.dart)
- **API Config**: All backend URLs in [frontend/lib/utils/constants.dart](../frontend/lib/utils/constants.dart) - **Update `baseUrl` for deployment**
- **i18n**: Supports English, French, Arabic (RTL) via `flutter_localizations` in `lib/l10n/`
- **Theme**: Centralized in [frontend/lib/utils/theme.dart](../frontend/lib/utils/theme.dart) - Primary: `#A4D7E1`, Secondary: `#A7E9A4`

## Critical Developer Workflows

### Starting Development
```bash
# Full stack with Docker (recommended)
docker-compose up -d

# Backend only (requires MongoDB running)
cd backend
npm install
npm run start:dev  # Watches TypeScript changes

# Frontend only
cd frontend
flutter pub get
flutter run  # Select device when prompted
```

### Environment Setup
- **Backend**: No `.env.example` exists - create `.env` with these keys (see [docker-compose.yml](../docker-compose.yml)):
  ```
  MONGODB_URI=mongodb://localhost:27017/cognicare
  JWT_SECRET=your-secret-key
  JWT_EXPIRATION=3600
  PORT=3000
  CORS_ORIGIN=http://localhost:3000
  ```
- **Frontend**: Update `AppConstants.baseUrl` in [frontend/lib/utils/constants.dart](../frontend/lib/utils/constants.dart) for non-localhost backends

### Testing & Linting
```bash
# Backend
npm run lint              # ESLint with auto-fix
npm run test              # Jest unit tests
npm run test:e2e          # E2E tests
npm run test:cov          # Coverage report

# Frontend
flutter analyze           # Dart analyzer
flutter test              # Widget/unit tests
```

### CI/CD
- GitHub Actions workflow at [.github/workflows/ci-cd.yml](../.github/workflows/ci-cd.yml)
- Runs on `main`/`develop` pushes: backend tests, Flutter analyze/test, Docker build
- **Note**: Docker Hub credentials required for deployment (`DOCKER_USERNAME`, `DOCKER_PASSWORD`)

## Project-Specific Conventions

### Backend Patterns
1. **DTOs with Decorators**: Use `class-validator` and Swagger decorators - example: [backend/src/auth/dto/signup.dto.ts](../backend/src/auth/dto/signup.dto.ts)
   ```typescript
   export class SignupDto {
     @ApiProperty({ example: 'john@example.com' })
     @IsEmail()
     email: string;
   }
   ```

2. **User Roles**: Enum `['family', 'doctor', 'volunteer']` enforced in [backend/src/schemas/user.schema.ts](../backend/src/schemas/user.schema.ts)

3. **Password Handling**: Always use bcrypt with 12 salt rounds (see [backend/src/auth/auth.service.ts](../backend/src/auth/auth.service.ts))

4. **Error Responses**: Custom filter at [backend/src/common/filters/http-exception.filter.ts](../backend/src/common/filters/http-exception.filter.ts) formats all errors consistently

### Frontend Patterns
1. **Navigation**: Use `context.go('/route')` from GoRouter, **not** `Navigator.push()` - routes defined in `AppConstants`

2. **API Calls**: Service layer pattern - see [frontend/lib/services/auth_service.dart](../frontend/lib/services/auth_service.dart)
   - All endpoints use `AppConstants.baseUrl` + endpoint path
   - JWT stored in `flutter_secure_storage` with key `AppConstants.jwtTokenKey`

3. **State Updates**: Call `notifyListeners()` after every state change in Providers

4. **Localization**: Use `AppLocalizations.of(context)!.translate('key')` for i18n strings

## Integration & Data Flow

### Authentication Flow
1. **Signup/Login**: Frontend → `POST /api/v1/auth/signup` or `/login` → Backend validates → Returns JWT + user object
2. **Token Storage**: Frontend saves JWT to secure storage via `AuthService`
3. **Authenticated Requests**: Frontend adds `Authorization: Bearer <token>` header (see `AuthService.getProfile()`)
4. **JWT Validation**: Backend uses `JwtAuthGuard` and `JwtStrategy` (Passport.js) to protect routes

### Cross-Component Communication
- **No direct coupling**: Frontend and backend communicate only via HTTP
- **API versioning**: All endpoints under `/api/v1` - increment version for breaking changes
- **CORS**: Backend allows origin from `CORS_ORIGIN` env var (default: `http://localhost:3000`)

## Key Files Reference
- **Backend Module Structure**: [backend/src/app.module.ts](../backend/src/app.module.ts)
- **Frontend App Entry**: [frontend/lib/main.dart](../frontend/lib/main.dart)
- **User Schema**: [backend/src/schemas/user.schema.ts](../backend/src/schemas/user.schema.ts)
- **Auth Service Logic**: [backend/src/auth/auth.service.ts](../backend/src/auth/auth.service.ts), [frontend/lib/providers/auth_provider.dart](../frontend/lib/providers/auth_provider.dart)
- **Docker Services**: [docker-compose.yml](../docker-compose.yml) - MongoDB, Backend, Frontend (nginx)

## Common Gotchas
- **Flutter API base URL**: Hardcoded to `localhost:3000` - change for mobile device testing (use host machine IP)
- **MongoDB initialization**: Script at [backend/init-mongo.js](../backend/init-mongo.js) runs on first Docker startup
- **Port conflicts**: Frontend nginx (8080), Backend (3000), MongoDB (27017)
- **Swagger auth**: Click "Authorize" in Swagger UI (`/api`) and enter JWT token to test protected endpoints
