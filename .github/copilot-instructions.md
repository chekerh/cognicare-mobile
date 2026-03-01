# CogniCare Mobile + Backend - AI Agent Instructions

## Project Overview

Full-stack cognitive health platform consisting of:
- **Backend**: NestJS REST API serving all frontends (Flutter mobile + React web dashboard)
- **Frontend**: Flutter cross-platform mobile app (iOS, Android, Web)

**Critical**: See root [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) for workspace-wide architecture, multi-tenancy model, and cross-project integration patterns.

## Technology Stack

### Backend (NestJS)
- **Framework**: NestJS 11.0.1 (TypeScript, decorators, dependency injection)
- **Database**: MongoDB 8.8.3 with Mongoose ODM
- **Authentication**: JWT (access: 15min, refresh: 7 days) + Passport.js
- **Validation**: class-validator + class-transformer (DTOs)
- **API Docs**: Swagger UI at `http://localhost:3000/api`
- **WebSockets**: Socket.IO for real-time call signaling
- **AI**: Google Gemini 1.5 Flash API for fraud detection, chatbot, progress recommendations
- **External Services**: SendGrid (email), Cloudinary (file uploads), PayPal (donations), Jitsi Meet (calls)

### Frontend (Flutter)
- **SDK**: Flutter >=3.24.0 (Dart 3.3.0+)
- **State Management**: Provider 6.1.1
- **Routing**: go_router 13.0.0 (declarative routing)
- **HTTP**: http 1.2.0 + http_parser 4.0.0
- **Secure Storage**: flutter_secure_storage 9.0.0 (JWT tokens)
- **i18n**: flutter_localizations + intl (EN, FR, AR with RTL)
- **Real-time**: flutter_webrtc 1.3.0 + socket_io_client 3.0.1
- **Maps**: flutter_map 7.0.2 + latlong2 0.9.1 (OpenStreetMap, no API key)
- **Media**: image_picker 1.0.7, file_picker 8.0.0+1, record 6.2.0, audioplayers 6.0.0

## Backend Architecture

### Current Structure (MVC-like Layered)

**Standard NestJS Module Pattern** (as of March 2026):
```
backend/src/
  <module-name>/
    dto/                        # Data Transfer Objects (validation, API contracts)
    schemas/                    # Mongoose schemas (MongoDB models)
    <module>.controller.ts      # HTTP endpoints, routing, guards
    <module>.service.ts         # Business logic, database operations
    <module>.module.ts          # Module definition, dependency injection
```

**Key Characteristics**:
- Controllers handle HTTP routing and guards (`@UseGuards(JwtAuthGuard, RolesGuard)`)
- Services contain business logic AND direct MongoDB calls (e.g., `this.userModel.find()`)
- Schemas define Mongoose models with decorators (`@Prop()`, `@Schema()`)
- DTOs use class-validator decorators (`@IsString()`, `@IsEmail()`, `@ApiProperty()`)

**Example**: [children/children.service.ts](backend/src/children/children.service.ts)
```typescript
async findByFamily(userId: string) {
  return this.childModel.find({ familyUserId: userId }).exec();
}
```

### Planned Architecture (Clean Architecture)

**From [backend/ToDo](backend/ToDo)** - Major refactor planned:

```
backend/src/
  <module-name>/
    domain/
      entities/                 # Plain TypeScript classes (no decorators)
      repositories/             # Repository interface contracts
    application/
      use-cases/                # Business logic (single responsibility)
      dto/                      # DTOs (API contracts)
    infrastructure/
      database/
        <module>.schema.ts      # Mongoose schemas
        <module>.mongo.repository.ts  # Repository implementation
    interface/
      controllers/              # HTTP controllers (call use cases)
    <module>.module.ts
```

**Why this matters**: When refactoring code:
1. **No direct DB calls in use cases** - inject repository interfaces
2. **Use cases should be testable without MongoDB** - mock repositories
3. **Separate concerns**: Controller → Use Case → Repository → Schema
4. **Current code will likely be refactored** - prefer patterns that align with Clean Architecture

## Module Catalog

### Core Authentication & Users
- **auth** ([auth.service.ts](backend/src/auth/auth.service.ts)): Email verification (6-digit code, 10min TTL), JWT signup/login, refresh tokens, password reset
- **users** ([users.controller.ts](backend/src/users/users.controller.ts)): User CRUD, profile updates, role management (9 roles - see root instructions)

### Organization & Multi-Tenancy
- **organization** ([organization.controller.ts](backend/src/organization/organization.controller.ts)): Org creation (auto on org_leader signup), staff management (add/remove staff, invite via email), family assignment
- **orgScanAi** ([orgScanAi.controller.ts](backend/src/orgScanAi/orgScanAi.controller.ts)): **AI fraud detection** for org certificates (Gemini 1.5 Flash, PDF parsing, embedding similarity, domain risk scoring)

### Child Management & Clinical Tools
- **children** ([children.controller.ts](backend/src/children/children.controller.ts)): Child profiles for families, assigned to org staff
- **specialized-plans** ([specialized-plans.controller.ts](backend/src/specialized-plans/specialized-plans.controller.ts)): **PECS/TEACCH therapy plans** for children with autism (image upload for PECS cards, schedule creation)
- **progress-ai** ([progress-ai.controller.ts](backend/src/progress-ai/progress-ai.controller.ts)): **AI-powered progress recommendations** using Gemini (analyze child's therapy sessions, parent feedback, specialist notes)
- **nutrition** ([nutrition.controller.ts](backend/src/nutrition/nutrition.controller.ts)): Meal plans, medication reminders, therapy task tracking

### Community & Social Features
- **community** ([community.controller.ts](backend/src/community/community.controller.ts)): Posts, comments, likes (family support network)
- **conversations** ([conversations.controller.ts](backend/src/conversations/conversations.controller.ts)): Private messaging (families ↔ staff/volunteers)
- **marketplace** ([marketplace.controller.ts](backend/src/marketplace/marketplace.controller.ts)): Service/goods exchange within community
- **donations** ([donations.controller.ts](backend/src/donations/donations.controller.ts)): Donation requests from families

### Gamification & Engagement
- **gamification** ([gamification.controller.ts](backend/src/gamification/gamification.controller.ts)): Points, badges, achievements for child exercises
- **engagement** ([engagement.controller.ts](backend/src/engagement/engagement.controller.ts)): Dashboard aggregating play time, activities, badges

### Real-Time Communication
- **calls** ([calls.gateway.ts](backend/src/calls/calls.gateway.ts)): **WebSocket call signaling** for Jitsi Meet (initiate, accept, reject, end)
- **chatbot** ([chatbot.controller.ts](backend/src/chatbot/chatbot.controller.ts)): **Conversational AI assistant** using Gemini (multi-turn chat with history)

### Volunteer System
- **volunteers** ([volunteers.controller.ts](backend/src/volunteers/volunteers.controller.ts)): Application submission, document upload (ID, criminal record), admin review/approval
- **courses** ([courses.controller.ts](backend/src/courses/courses.controller.ts)): Training courses for volunteers (qualification tracking, enrollment)
- **certification-test** ([certification-test.controller.ts](backend/src/certification-test/certification-test.controller.ts)): Certification tests for courses
- **availabilities** ([availabilities.controller.ts](backend/src/availabilities/availabilities.controller.ts)): Volunteer time slot posting

### External Services & Integrations
- **cloudinary** ([cloudinary.service.ts](backend/src/cloudinary/cloudinary.service.ts)): File uploads (images, PDFs) - **REQUIRED for org certificates**
- **mail** ([mail.service.ts](backend/src/mail/mail.service.ts)): SendGrid email service with mock mode for dev (`NODE_ENV=development`)
- **paypal** ([paypal.controller.ts](backend/src/paypal/paypal.controller.ts)): Payment processing for donations
- **notifications** ([notifications.controller.ts](backend/src/notifications/notifications.controller.ts)): In-app notifications (course enrollment, volunteer updates)
- **healthcare-cabinets** ([healthcare-cabinets.controller.ts](backend/src/healthcare-cabinets/healthcare-cabinets.controller.ts)): Healthcare facility directory (OpenStreetMap Overpass API, no API key)
- **integrations** ([integrations.controller.ts](backend/src/integrations/integrations.controller.ts)): External service integrations

### Admin & Import Tools
- **import** ([import.controller.ts](backend/src/import/import.controller.ts)): **Two-step Excel import** (preview → confirm) for staff, families, children (ExcelJS parsing, auto-detect columns)
- **training** ([training.controller.ts](backend/src/training/training.controller.ts)): Staff training modules

### Infrastructure
- **database** ([database.module.ts](backend/src/database/database.module.ts)): MongoDB connection (Mongoose)
- **health** ([health.controller.ts](backend/src/health/health.controller.ts)): Health checks (`/api/v1/health`)
- **common**: Global filters, guards, decorators ([common/](backend/src/common/))

## Critical Backend Patterns

### 1. Role-Based Access Control

**Role Hierarchy** (from [user.schema.ts](backend/src/users/schemas/user.schema.ts)):
```typescript
role: 'family' | 'doctor' | 'volunteer' | 'admin' | 'organization_leader' 
      | 'psychologist' | 'speech_therapist' | 'occupational_therapist' | 'other'
```

**Self-Signup Roles**: `family`, `doctor`, `volunteer`, `organization_leader`
**Org-Only Roles** (assigned by org leaders): `psychologist`, `speech_therapist`, `occupational_therapist`, `other`
**Admin Role**: **Only created via direct DB insertion** (security - prevents privilege escalation)

**Usage in Controllers**:
```typescript
@Roles('psychologist', 'speech_therapist', 'occupational_therapist', 'doctor', 'volunteer')
@UseGuards(JwtAuthGuard, RolesGuard)
async createPlan(@Request() req: { user: { id: string; role: string } }) {
  // Only specialists can create plans
}
```

### 2. Email Verification Flow (Unique Two-Step Signup)

**Step 1**: `POST /auth/send-verification-code`
- Hashed 6-digit code stored in `email_verifications` collection (TTL: 10min)
- SendGrid sends email (or console log in dev mode)

**Step 2**: `POST /auth/signup`
- Body includes `verificationCode` field
- **Organization leaders**: MUST upload PDF certificate → triggers AI fraud analysis → NO tokens returned (pending approval)
- **Other roles**: Returns `{ accessToken, refreshToken, user }`

**Critical**: Organization leader signup **requires Cloudinary configured**, otherwise PDF upload fails.

### 3. File Upload Pattern

**Cloudinary Integration** ([cloudinary.service.ts](backend/src/cloudinary/cloudinary.service.ts)):
```typescript
@Post('upload-post-image')
@UseInterceptors(FileInterceptor('file'))
async uploadPostImage(@UploadedFile() file: { buffer: Buffer; mimetype: string }) {
  // Validate mimetype: image/jpeg, image/png, image/webp
  const imageUrl = await this.cloudinaryService.uploadBuffer(file);
  return { imageUrl };
}
```

**PDF Upload** (org certificates):
```typescript
const pdfUrl = await this.cloudinaryService.uploadRawBuffer(file.buffer);
// PDF parsing using pdf-parse (lazy load via dynamic import - see root instructions)
```

### 4. WebSocket Gateway Pattern (Calls)

**Connection** ([calls.gateway.ts](backend/src/calls/calls.gateway.ts)):
```typescript
@WebSocketGateway({ cors: true, namespace: '/', transports: ['websocket', 'polling'] })
@UseGuards(WsJwtGuard)
export class CallsGateway {
  @SubscribeMessage('call:initiate')
  handleInitiate(@MessageBody() data: { targetUserId: string; channelId: string; callerName: string }) {
    // Route to recipient's socket(s) via userId → socketId map
  }
}
```

**Authentication**: JWT validated on connection, `userId` stored in `userIdToSocket` map.

### 5. AI Service Integration (Gemini)

**Pattern** (from [progress-ai/llm.service.ts](backend/src/progress-ai/llm.service.ts)):
```typescript
private async callGemini(prompt: string): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`;
  const response = await axios.post(url, { contents: [{ parts: [{ text: prompt }] }] }, { timeout: 30000 });
  return response.data.candidates[0].content.parts[0].text;
}
```

**Usage**:
- **OrgScanAi**: Extract structured JSON from PDF text (org name, registration number, etc.)
- **Chatbot**: Multi-turn conversation with message history
- **Progress AI**: Generate personalized recommendations based on child's data

**Error Handling**: Always check `GEMINI_API_KEY` env var, provide health check endpoint.

### 6. Two-Step Import Flow (Excel)

**Pattern** ([import.controller.ts](backend/src/import/import.controller.ts)):
1. **Preview**: `POST /import/preview/:orgId/:type` → Upload Excel → Auto-detect columns → Return suggested mappings + sample rows
2. **Execute**: `POST /import/execute/:orgId/:type` → Upload same Excel + confirmed mappings → Run import

**Supports**: Staff, families, children, family-children (combo)

**Technology**: ExcelJS for parsing, class-validator for row validation.

### 7. Definite Assignment Pattern (TypeScript Strict Mode)

**All DTOs and schemas use `!` assertion**:
```typescript
export class SignupDto {
  @IsEmail()
  @ApiProperty()
  email!: string;  // NOT `email: string` - strict mode compatible

  @IsString()
  password!: string;
}
```

**Why**: Ensures TypeScript strict mode compatibility, prevents "property has no initializer" errors.

## Flutter Frontend Architecture

### Project Structure

```
frontend/lib/
  main.dart                   # Entry point, Provider setup, theme, i18n
  models/                     # Data models (User, Child, Organization, Post, etc.)
  providers/                  # State management (auth_provider, language_provider, etc.)
  screens/                    # UI screens (home, auth, child profile, community, etc.)
  services/                   # API clients (auth_service, children_service, etc.)
  utils/
    constants.dart            # API base URL, JWT token key, colors
    router.dart               # GoRouter declarative routing
  widgets/                    # Reusable UI components
  l10n/                       # Localization files (app_en.arb, app_fr.arb, app_ar.arb)
```

### Key Patterns

#### 1. API Service Pattern

**Base Pattern** ([services/auth_service.dart](frontend/lib/services/auth_service.dart)):
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class AuthService {
  final _secureStorage = FlutterSecureStorage();

  Future<Map<String, dynamic>> signup(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _secureStorage.write(key: AppConstants.jwtTokenKey, value: data['accessToken']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }
}
```

**Authenticated Requests**:
```dart
Future<Map<String, dynamic>> getProfile() async {
  final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
  final response = await http.get(
    Uri.parse('${AppConstants.baseUrl}/api/v1/users/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  // Error handling...
}
```

#### 2. Provider State Management

**Pattern** ([providers/auth_provider.dart](frontend/lib/providers/auth_provider.dart)):
```dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.login(email, password);
      _user = User.fromJson(data['user']);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Usage in Widgets**:
```dart
final authProvider = Provider.of<AuthProvider>(context);
if (authProvider.isLoading) {
  return CircularProgressIndicator();
}
```

#### 3. GoRouter Declarative Routing

**Pattern** ([utils/router.dart](frontend/lib/utils/router.dart)):
```dart
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/child/:id',
      builder: (context, state) {
        final childId = state.pathParameters['id']!;
        return ChildDetailScreen(childId: childId);
      },
    ),
  ],
);
```

**Navigation**:
```dart
context.go('/child/123');  // Replace route stack
context.push('/settings'); // Add to stack
context.pop();             // Go back
```

#### 4. `mounted` Check Pattern (Critical for Async)

**Anti-Pattern** (causes exceptions):
```dart
await someAsyncOperation();
if (mounted) {  // TOO LATE - context already used in Navigator below
  Navigator.pop(context);  // ERROR: Don't use 'BuildContext's across async gaps
}
```

**Correct Pattern**:
```dart
final navigator = Navigator.of(context);
final messenger = ScaffoldMessenger.of(context);
final router = GoRouter.of(context);

await someAsyncOperation();

if (mounted) {
  navigator.pop();
  messenger.showSnackBar(SnackBar(content: Text('Success')));
  router.go('/home');
}
```

**Why**: Capture `Navigator`, `ScaffoldMessenger`, `GoRouter` **before** `await` to avoid context issues.

#### 5. Internationalization (i18n)

**Setup** ([main.dart](frontend/lib/main.dart)):
```dart
MaterialApp.router(
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    AppLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('en', ''),
    Locale('fr', ''),
    Locale('ar', ''),
  ],
  locale: languageProvider.locale,
)
```

**Usage in Widgets**:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.welcomeMessage)
```

**RTL Support**: Automatically applied for Arabic via `Directionality` widget.

## Development Workflows

### Backend Local Development

```bash
cd cognicare-mobile/backend
npm install
npm run start:dev  # Watch mode, auto-reload
# API: http://localhost:3000/api/v1
# Swagger: http://localhost:3000/api
```

**Environment Setup**:
- Copy `docker-compose.yml` env vars to local `.env` file
- **Development mode**: Set `NODE_ENV=development` for email mock service
- **Production**: Requires `SENDGRID_API_KEY`, `CLOUDINARY_*`, `GEMINI_API_KEY`

**MongoDB**:
- **Local**: `mongodb://localhost:27017/cognicare`
- **Docker**: `docker-compose up -d mongodb` → `mongodb://mongodb:27017/cognicare`
- **Production**: MongoDB Atlas connection string

### Frontend Local Development

```bash
cd cognicare-mobile/frontend
flutter pub get
flutter run
# or
flutter run -d chrome              # Web browser
flutter run -d <device-id>         # iOS/Android device/emulator
```

**API Configuration** ([utils/constants.dart](frontend/lib/utils/constants.dart)):
```dart
static const String baseUrl = 'http://localhost:3000';
// For physical devices: 'http://192.168.x.x:3000' (find IP with `ipconfig getifaddr en0`)
```

**i18n Updates**:
```bash
flutter gen-l10n  # After updating .arb files
```

### Docker Compose (Full Stack)

```bash
cd cognicare-mobile
docker-compose up -d  # Starts mongodb, backend, frontend
docker-compose logs -f backend  # View backend logs
docker-compose down  # Stop all services
```

**Health Check**: `curl http://localhost:3000/api/v1/health`

### Testing Backend API (Swagger)

1. Navigate to `http://localhost:3000/api`
2. Get JWT token from signup/login response
3. Click "Authorize" → Enter `Bearer <your-jwt-token>`
4. Test protected endpoints

### Database Management

**MongoDB Compass**: `mongodb://localhost:27017/cognicare`

**Manual Admin User Creation** (security - no API route):
```javascript
db.users.insertOne({
  email: 'admin@cognicare.tn',
  password: '$2a$12$hashedPassword',  // bcrypt hash
  role: 'admin',
  firstName: 'Admin',
  lastName: 'User',
  isEmailVerified: true,
  createdAt: new Date(),
  updatedAt: new Date()
})
```

## Common Gotchas

### Backend

1. **Admin Creation**: Never expose admin role in signup DTO - security risk
2. **PDF Parsing**: Use lazy load helper for `pdf-parse` (see root instructions) - ESM module issues
3. **Cloudinary Required**: Organization leader signup fails without Cloudinary configured
4. **Email in Dev**: Set `NODE_ENV=development` to skip SendGrid (mock mode logs to console)
5. **JWT Guards**: Always use `@UseGuards(JwtAuthGuard, RolesGuard)` + `@ApiBearerAuth()` for protected routes
6. **Mongoose Queries**: Always call `.exec()` on queries for proper Promise typing
7. **CORS**: Backend allows `localhost:3000`, `localhost:8080`, `localhost:54200-54202` - add production origin to `CORS_ORIGIN`
8. **WebSocket Auth**: JWT validated on connection, not per message - store `userId` in gateway
9. **Gemini Timeout**: 30-second timeout for free tier (Render compatible) - handle gracefully
10. **Definite Assignment**: All DTO/schema properties use `!` assertion for TypeScript strict mode

### Frontend

1. **`mounted` Checks**: Capture `Navigator`, `ScaffoldMessenger`, `GoRouter` **before** `await`
2. **baseUrl for Devices**: Change to host machine IP (`192.168.x.x:3000`) for physical device testing
3. **JWT Storage**: Use `flutter_secure_storage` (encrypted), NOT shared_preferences (plaintext)
4. **Hot Reload in Docker**: Won't work - use `flutter run` locally for development
5. **RTL Support**: Test Arabic translations - some widgets need explicit `textDirection`
6. **`intl` Version**: Managed by `flutter_localizations` - don't manually update
7. **Image Picker Permissions**: iOS requires `Info.plist` entries for camera/photo library
8. **WebRTC on Web**: May have CORS issues - test on mobile first
9. **GoRouter State**: Use `state.pathParameters` for URL params, `state.extra` for object passing
10. **Provider `listen`**: Use `listen: false` in event handlers (`Provider.of<T>(context, listen: false)`)

## Future Architecture Direction

**From [backend/ToDo](backend/ToDo)**: The backend is planned to be **rebuilt from scratch** using **Clean Architecture**:

**When refactoring/adding features**:
- ✅ **Prefer**: Use cases, repository interfaces, dependency injection
- ✅ **Prefer**: Separate business logic from database logic
- ✅ **Prefer**: Testable code (mock repositories, no direct DB calls in use cases)
- ❌ **Avoid**: Direct `this.model.find()` calls in new code
- ❌ **Avoid**: Mixing concerns (HTTP + business logic + DB in one service)

**Current code will be refactored** - align new code with Clean Architecture principles where possible.

## Key Files Reference

### Backend Core
- [main.ts](backend/src/main.ts) - Bootstrap, global config, Swagger, CORS, rate limiting
- [app.module.ts](backend/src/app.module.ts) - Module imports, global providers
- [database/database.module.ts](backend/src/database/database.module.ts) - MongoDB connection
- [common/filters/http-exception.filter.ts](backend/src/common/filters/http-exception.filter.ts) - Global error handling

### Backend Auth & Security
- [auth/auth.service.ts](backend/src/auth/auth.service.ts) - Email verification, JWT, signup/login
- [auth/jwt-auth.guard.ts](backend/src/auth/jwt-auth.guard.ts) - JWT validation guard
- [auth/roles.guard.ts](backend/src/auth/roles.guard.ts) - Role-based access guard
- [users/schemas/user.schema.ts](backend/src/users/schemas/user.schema.ts) - User model with 9 roles

### Backend Key Modules
- [orgScanAi/fraud-analysis.service.ts](backend/src/orgScanAi/fraud-analysis.service.ts) - AI fraud detection orchestrator
- [specialized-plans/specialized-plans.service.ts](backend/src/specialized-plans/specialized-plans.service.ts) - PECS/TEACCH therapy plans
- [progress-ai/progress-ai.service.ts](backend/src/progress-ai/progress-ai.service.ts) - AI progress recommendations
- [chatbot/chatbot.service.ts](backend/src/chatbot/chatbot.service.ts) - Conversational AI assistant
- [calls/calls.gateway.ts](backend/src/calls/calls.gateway.ts) - WebSocket call signaling
- [import/import.controller.ts](backend/src/import/import.controller.ts) - Two-step Excel import

### Frontend Core
- [main.dart](frontend/lib/main.dart) - App entry, Provider setup, theme, localization
- [utils/constants.dart](frontend/lib/utils/constants.dart) - **UPDATE for deployment** (baseUrl)
- [utils/router.dart](frontend/lib/utils/router.dart) - GoRouter routes
- [providers/auth_provider.dart](frontend/lib/providers/auth_provider.dart) - Auth state management
- [services/auth_service.dart](frontend/lib/services/auth_service.dart) - API client for auth endpoints

### DevOps
- [docker-compose.yml](docker-compose.yml) - Multi-service orchestration (MongoDB, backend, frontend)
- [backend/Dockerfile](backend/Dockerfile) - Backend production image
- [frontend/Dockerfile](frontend/Dockerfile) - Flutter web production image
- [render.yaml](render.yaml) - Render.com deployment config

## Additional Resources

- **Workspace-wide patterns**: See [root `.github/copilot-instructions.md`](../../.github/copilot-instructions.md)
- **Web dashboard patterns**: See [Cognicare_Web_Dashboard/.github/copilot-instructions.md](../../Cognicare_Web_Dashboard/.github/copilot-instructions.md)
- **Swagger API Docs**: `http://localhost:3000/api` (local development)
- **NestJS Docs**: https://docs.nestjs.com/
- **Flutter Docs**: https://docs.flutter.dev/
