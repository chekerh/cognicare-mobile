# CogniCare Mobile + Backend AI Agent Instructions

## Project Overview

Dual-component cognitive health platform:
- **Backend** (`backend/`): NestJS REST API with MongoDB persistence
- **Frontend** (`frontend/`): Flutter cross-platform mobile app (iOS, Android, Web)

Both live in `cognicare-mobile/` with shared Docker orchestration. The web dashboard lives in sibling `Cognicare_Web_Dashboard/` directory and shares this same backend.

**Critical**: See root [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) for workspace-wide architecture, multi-tenancy model, and cross-project integration patterns.

## Backend Architecture (NestJS)

### Module Structure Pattern

All features follow the same NestJS module structure:
```
module-name/
├── module-name.controller.ts   # API endpoints, guards, validation
├── module-name.service.ts      # Business logic, database operations
├── module-name.module.ts       # Dependency injection configuration
├── dto/                        # Request/response DTOs with class-validator
│   ├── create-*.dto.ts
│   └── update-*.dto.ts
└── schemas/                    # Mongoose schemas (MongoDB models)
    └── *.schema.ts
```

**Key modules** (from [app.module.ts](../backend/src/app.module.ts)):
- **Auth**: JWT authentication, email verification, password reset, presence tracking
- **Users**: User CRUD, profile management, role-based access
- **Organization**: Multi-tenancy, staff/family management, org leader dashboard
- **Community**: Social posts, comments, likes, image uploads
- **Marketplace**: Products, donations, transactions
- **Conversations**: Private messaging between users
- **Children**: Child profiles for family users, linked to org support
- **Availabilities**: Volunteer time slot posting
- **Gamification**: Points, badges, achievements for child engagement
- **Courses**: Educational content for volunteers
- **Cloudinary**: Image upload service integration
- **Volunteers**: Volunteer applications, document verification

### API Endpoint Patterns

**Global prefix**: All endpoints start with `/api/v1` (from [main.ts](../backend/src/main.ts#L81))

**Swagger documentation**: Available at `http://localhost:3000/api` in development

**Standard controller decorators**:
```typescript
@ApiTags('module-name')          // Swagger grouping
@ApiBearerAuth('JWT-auth')       // Requires JWT in Swagger
@UseGuards(JwtAuthGuard)         // Requires valid JWT token
@Controller('module-name')       // Route prefix
export class ModuleController {
  
  @Get('path')
  @Roles('admin', 'organization_leader')  // Role-based access control
  @ApiOperation({ summary: 'Describe what this does' })
  async getMethod(@Request() req: any) {
    const userId = req.user.id;  // JWT payload injected by strategy
    // ...
  }
}
```

**Request user object** (injected by JWT strategy):
```typescript
req.user = {
  id: string,         // User's MongoDB _id
  email: string,
  role: string,       // One of the user roles
}
```

### Authentication & Authorization Patterns

**Email verification flow** (unique two-step pattern):
1. `POST /auth/send-verification-code` - Generates 6-digit code, sends via SendGrid
   - Code hashed with bcrypt, stored in `email_verifications` collection
   - TTL index auto-deletes after 10 minutes
2. `POST /auth/signup` - Creates user with `verificationCode` field in body
   - Backend hashes submitted code, queries MongoDB
   - If valid, creates user + deletes verification doc
   - Returns `{ accessToken, refreshToken, user }`

**JWT token pattern**:
- **Access token**: 15 minutes (from [auth.service.ts](../backend/src/auth/auth.service.ts#L65))
- **Refresh token**: 7 days, stored hashed in user document

**Role-based access control**:
```typescript
// In controller
@Roles('organization_leader', 'admin')  // Multiple roles allowed
@UseGuards(JwtAuthGuard, RolesGuard)
async protectedMethod() { }

// Self-signup roles (from /auth/signup):
'family', 'doctor', 'volunteer', 'organization_leader'

// Organization-only roles (created via org staff management):
'psychologist', 'speech_therapist', 'occupational_therapist', 'other'

// Admin role: MUST be created via direct DB insertion (security)
```

**Organization access pattern** (from [organization.controller.ts](../backend/src/organization/organization.controller.ts)):
```typescript
// "My organization" endpoints - uses logged-in user's org
@Get('my-organization')
@Roles('organization_leader')
async getMyOrganization(@Request() req: any) {
  return await this.organizationService.getMyOrganization(req.user.id);
}

// By ID endpoints - requires org leader to own that org
@Get(':orgId/staff')
@Roles('organization_leader')
async getStaff(@Param('orgId') orgId: string, @Request() req: any) {
  // Service must verify req.user.id is leader of orgId
}
```

### File Upload Pattern

**Image upload via Cloudinary** (from [community.controller.ts](../backend/src/community/community.controller.ts#L37-L51)):
```typescript
@Post('upload-post-image')
@UseInterceptors(FileInterceptor('file'))
async uploadPostImage(
  @UploadedFile() file?: { buffer: Buffer; mimetype: string }
) {
  if (!file || !file.buffer) throw new BadRequestException('No file provided');
  
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!allowed.includes(file.mimetype)) throw new BadRequestException('Invalid type');
  
  const imageUrl = await this.cloudinaryService.uploadBuffer(file.buffer);
  return { imageUrl };
}
```
**PDF upload validation** (from [auth.controller.ts](../backend/src/auth/auth.controller.ts#L218)):
```typescript
// Organization leader signup requires PDF certificate
if (signupDto.role === 'organization_leader') {
  if (!certificate) throw new BadRequestException('Certificate PDF required');
  
  // Validate mimetype
  if (certificate.mimetype !== 'application/pdf') {
    throw new BadRequestException(`Certificate must be PDF (received ${certificate.mimetype})`);
  }
  
  // Validate PDF magic bytes (file signature)
  const pdfHeader = certificate.buffer.toString('utf8', 0, 5);
  if (!pdfHeader.startsWith('%PDF-')) {
    throw new BadRequestException(
      'Invalid PDF file. Does not have valid PDF header. Ensure genuine PDF document.'
    );
  }
  
  // Validate file size (max 10MB)
  const maxSize = 10 * 1024 * 1024;
  if (certificate.size > maxSize) {
    throw new BadRequestException(`PDF too large (${(certificate.size/1024/1024).toFixed(2)}MB). Max 10MB.`);
  }
}
```
**Cloudinary configuration** (REQUIRED for organization creation, optional for other features):
- Requires `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` env vars
- **CRITICAL**: Organization leader signup REQUIRES PDF certificate upload to Cloudinary - signup will fail without Cloudinary configured
- Service checks `isConfigured()` before attempting uploads
- Optional for: community post images, profile pictures, donation images (gracefully degrades)
- Required for: organization certificates (PDF - mandatory for org leader signup)

**Local file serving** (from [main.ts](../backend/src/main.ts#L21-L24)):
```typescript
// Serves uploaded files at /uploads/*
const uploadsPath = join(process.cwd(), 'uploads');
app.use('/uploads', express.static(uploadsPath, { index: false }));
```

### Database Patterns (MongoDB + Mongoose)

**Connection string strategy** (from root copilot-instructions.md):
- Local dev: `mongodb://localhost:27017/cognicare`
- Docker: `mongodb://mongodb:27017/cognicare` (service name)
- Production: MongoDB Atlas connection string

**Schema patterns** (from [user.schema.ts](../backend/src/users/schemas/user.schema.ts)):
```typescript
@Schema({ timestamps: true })  // Auto createdAt/updatedAt
export class User {
  @Prop({ required: true })
  fullName: string;
  
  @Prop({ required: true, unique: true })
  email: string;
  
  @Prop({ type: 'ObjectId', ref: 'Organization' })  // Foreign key reference
  organizationId?: string;
  
  @Prop({ type: [{ type: Types.ObjectId, ref: 'Child' }] })  // Array of refs
  childrenIds?: Types.ObjectId[];
}
```

**Common query patterns**:
```typescript
// Populate references
await this.userModel.findById(id).populate('organizationId').exec();

// Unset fields
await this.userModel.findByIdAndUpdate(
  userId,
  { $unset: { organizationId: 1 } },  // Remove field
  { new: true }
);

// Add to array
await this.organizationModel.findByIdAndUpdate(
  orgId,
  { $push: { staffIds: userId } }
);

// Remove from array
await this.organizationModel.findByIdAndUpdate(
  orgId,
  { $pull: { staffIds: userId } }
);
```

### Critical Backend Workflows

**Starting development**:
```bash
cd backend
npm install
npm run start:dev  # Watch mode with hot reload
```

**Testing**:
```bash
npm test           # Unit tests
npm run test:e2e   # E2E tests
npm run test:cov   # Coverage report
```

**Building for production**:
```bash
npm run build      # Outputs to dist/
npm run start:prod # Runs compiled JS
```

**Database initialization** (Docker only):
- [init-mongo.js](../backend/init-mongo.js) runs on first MongoDB startup
- Creates indexes for performance (e.g., `email_verifications` TTL index)

**Environment variables** (no .env.example - see root copilot-instructions.md):
```env
MONGODB_URI=mongodb://localhost:27017/cognicare
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRATION=3600                    # Access token lifetime (seconds)
SENDGRID_API_KEY=your-key              # Required for email verification
MAIL_FROM=verified@yourdomain.com      # Must be verified in SendGrid
BCRYPT_ROUNDS=12                       # Password hashing cost
THROTTLE_TTL=60000                     # Rate limit window (ms)
THROTTLE_LIMIT=10                      # Max requests per window
CLOUDINARY_CLOUD_NAME=your-cloud       # REQUIRED for organization certificate uploads, optional for general images
CLOUDINARY_API_KEY=your-api-key        # REQUIRED for organization certificate uploads, optional for general images
CLOUDINARY_API_SECRET=your-api-secret  # REQUIRED for organization certificate uploads, optional for general images
PAYPAL_CLIENT_ID=your-paypal-client-id          # Optional - for payment processing
PAYPAL_CLIENT_SECRET=your-paypal-secret         # Optional - for payment processing
GEMINI_API_KEY=your-gemini-api-key              # Required for orgScanAi fraud detection
```

**Mock email service**: Set `NODE_ENV=development` to use `MailMockService` (logs to console, no SendGrid needed)

## Frontend Architecture (Flutter)

### State Management Pattern (Provider)

**Provider hierarchy** (from [main.dart](../frontend/lib/main.dart#L42-L77)):
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: _authProvider),
    ChangeNotifierProvider.value(value: _themeProvider),
    ChangeNotifierProvider(create: (_) => CallProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => CommunityFeedProvider()),
    ChangeNotifierProvider(create: (_) => StickerBookProvider()),
    ChangeNotifierProvider(create: (_) => ChildSecurityCodeProvider()),
    ChangeNotifierProvider(create: (_) => ChildModeSessionProvider()),
    
    // Proxy provider - depends on AuthProvider
    ChangeNotifierProxyProvider<AuthProvider, GamificationProvider>(
      create: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return GamificationProvider(
          gamificationService: GamificationService(
            getToken: () async => authProvider.accessToken,
          ),
          childrenService: ChildrenService(
            getToken: () async => authProvider.accessToken,
          ),
        );
      },
      update: (context, authProvider, previous) => previous ?? /* create new */,
    ),
  ],
  child: MaterialApp.router(/* ... */),
)
```

**Provider pattern** (from [auth_provider.dart](../frontend/lib/providers/auth_provider.dart)):
```dart
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _accessToken;
  
  User? get user => _user;
  bool get isAuthenticated => _accessToken != null && _user != null;
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();  // Update UI immediately
    
    try {
      final response = await _authService.login(email, password);
      _accessToken = response.accessToken;
      _user = response.user;
      notifyListeners();  // Update UI with data
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();  // Update UI on error
      rethrow;  // Let widget handle error display
    }
  }
  
  void updateUser(User user) {
    _user = user;
    notifyListeners();
    _authService.saveUser(user);  // Persist to secure storage
  }
}
```

**Consuming providers in widgets**:
```dart
// Rebuild when provider changes
final auth = Provider.of<AuthProvider>(context);
final user = context.watch<AuthProvider>().user;

// Don't rebuild (for callbacks)
final auth = Provider.of<AuthProvider>(context, listen: false);
final auth = context.read<AuthProvider>();
```

### Navigation Pattern (GoRouter)

**Route configuration** (from [router.dart](../frontend/lib/utils/router.dart)):
```dart
GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,  // Rebuild routes when auth changes
    redirect: _redirect,              // Global redirect logic
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      // Shell route for bottom nav
      ShellRoute(
        builder: (context, state, child) => FamilyShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppConstants.familyDashboardRoute,
            builder: (context, state) => const FamilyMemberDashboardScreen(),
          ),
        ],
      ),
    ],
  );
}

String? _redirect(BuildContext context, GoRouterState state) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final isAuth = auth.isAuthenticated;
  final location = state.uri.path;
  final role = auth.user?.role;
  
  // Public routes (no JWT required)
  final isPublic = AppConstants.publicRoutes.any((r) => location == r);
  if (!isAuth && !isPublic) return AppConstants.loginRoute;
  
  // Role-based dashboard redirect
  if (isAuth && location == AppConstants.loginRoute) {
    if (AppConstants.isFamilyRole(role)) return AppConstants.familyDashboardRoute;
    if (AppConstants.isVolunteerRole(role)) return AppConstants.volunteerDashboardRoute;
    // ...
  }
  
  return null;  // Allow navigation
}
```

**Navigation in widgets**:
```dart
// Navigate to route
context.go(AppConstants.familyDashboardRoute);

// Navigate with parameters
context.go('/product/${productId}');

// Go back
context.pop();

// Replace current route
context.replace('/new-route');
```

### Service Pattern (HTTP API calls)

**Service structure** (all in `lib/services/`):
```dart
class AuthService {
  Future<LoginResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Login failed');
    }
  }
  
  // Secure storage for JWT tokens
  final _secureStorage = const FlutterSecureStorage();
  
  Future<void> saveToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.jwtTokenKey,
      value: token,
    );
  }
  
  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: AppConstants.jwtTokenKey);
  }
}
```

**Authenticated requests**:
```dart
class CommunityService {
  final Future<String?> Function() getToken;
  
  CommunityService({required this.getToken});
  
  Future<List<Post>> getPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    // Handle response...
  }
}
```

**Image upload pattern**:
```dart
Future<String> uploadImage(File imageFile) async {
  final token = await getToken();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${AppConstants.baseUrl}/api/v1/community/upload-post-image'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  
  final response = await request.send();
  final responseData = await response.stream.bytesToString();
  final data = jsonDecode(responseData) as Map<String, dynamic>;
  
  return data['imageUrl'] as String;
}
```

**Available Flutter Services** (all in `lib/services/`):
- `admin_service.dart` - Admin-specific operations
- `auth_service.dart` - Authentication, JWT token management, secure storage
- `availability_service.dart` - Volunteer availability slots
- `call_service.dart` - WebSocket call signaling, Jitsi Meet integration
- `chat_service.dart` - Real-time messaging, voice messages
- `children_service.dart` - Child profile management
- `community_service.dart` - Social posts, comments, likes
- `courses_service.dart` - Volunteer training courses
- `donation_service.dart` - Donation requests and contributions
- `engagement_service.dart` - Child engagement metrics and dashboard
- `gamification_service.dart` - Points, badges, achievements
- `geocoding_service.dart` - Reverse geocoding for addresses
- `healthcare_service.dart` - Medical records and health tracking
- `marketplace_service.dart` - Product listings and transactions
- `notification_service.dart` - Local notifications setup
- `notifications_feed_service.dart` - In-app notification feed
- `nutrition_service.dart` - Meal plans and nutrition tracking
- `paypal_service.dart` - PayPal payment integration
- `reminders_service.dart` - Task reminders and alerts
- `volunteer_service.dart` - Volunteer applications and documents

### Critical Flutter Workflows

**Starting development**:
```bash
cd frontend
flutter pub get                    # Install dependencies
flutter run                        # Auto-detects device
flutter run -d chrome              # Web browser
flutter run -d <device-id>         # Specific device
```

**Device testing**:
```bash
flutter devices                    # List available devices
flutter run --dart-define=BASE_URL=http://192.168.1.100:3000  # Physical device
```

**Building**:
```bash
flutter build apk                  # Android APK
flutter build ios                  # iOS (requires macOS + Xcode)
flutter build web                  # Web (outputs to build/web/)
```

**Configuration** (from [constants.dart](../frontend/lib/utils/constants.dart)):
```dart
// API base URL - change for physical device testing
static const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://127.0.0.1:3000',  // Simulator/emulator default
);

// For physical device: flutter run --dart-define=BASE_URL=http://YOUR_IP:3000
// Backend must bind to 0.0.0.0 (not 127.0.0.1) for device access
```

**Key Flutter Dependencies** (from [pubspec.yaml](../frontend/pubspec.yaml)):
- `provider: ^6.1.1` - State management
- `go_router: ^13.0.0` - Declarative routing
- `http: ^1.2.0` + `http_parser: ^4.0.0` - HTTP client for REST API
- `flutter_secure_storage: ^9.0.0` - Encrypted JWT token storage
- `shared_preferences: ^2.2.2` - App settings persistence
- `jitsi_meet_flutter_sdk: ^11.6.0` - Voice/video calls (Jitsi Meet, free, no API key)
- `socket_io_client: ^3.0.1` - WebSocket for call signaling and real-time chat
- `flutter_local_notifications: ^18.0.1` - Local notifications (incoming calls, messages)
- `image_picker: ^1.0.7` - Pick images from gallery/camera
- `file_picker: ^8.0.0+1` - Pick documents (PDF, images)
- `path_provider: ^2.1.2` - File system paths
- `record: ^6.2.0` - Audio recording (voice messages)
- `audioplayers: ^6.0.0` - Audio playback (voice messages)
- `flutter_map: ^7.0.2` + `latlong2: ^0.9.1` - OpenStreetMap integration (free, no API key)
- `geolocator: ^13.0.2` - GPS positioning and distance calculation
- `share_plus: ^10.0.0` - Native sharing
- `url_launcher: ^6.2.2` - Open URLs in browser

**Localization** (multi-language support):
```dart
// In widget
final t = AppLocalizations.of(context)!;
Text(t.welcome)  // Reads from .arb files

// Change language (via LanguageProvider)
context.read<LanguageProvider>().setLanguage('fr');
```

### Flutter-Specific Patterns & Gotchas

**Widget `mounted` checks** (async safety):
```dart
// ❌ WRONG - widget may be disposed after await
await someAsyncOperation();
Navigator.of(context).pop();  // May crash

// ✅ CORRECT - capture before await
final navigator = Navigator.of(context);
final scaffoldMessenger = ScaffoldMessenger.of(context);
await someAsyncOperation();
if (!mounted) return;
navigator.pop();
scaffoldMessenger.showSnackBar(/* ... */);
```

**GoRouter context capture**:
```dart
// ❌ WRONG - context may be invalid
await someAsyncOperation();
context.go('/dashboard');  // May throw

// ✅ CORRECT - capture router before await
final router = GoRouter.of(context);
await someAsyncOperation();
if (mounted) router.go('/dashboard');
```

**Deprecated Flutter APIs** (current Flutter >=3.24.0):
```dart
// ❌ Deprecated
Color.withOpacity(0.5)

// ✅ Current
Color.withValues(alpha: 0.5)
```

**Provider updates in async operations**:
```dart
// Always check mounted before notifyListeners
Future<void> fetchData() async {
  final data = await api.getData();
  if (!mounted) return;  // Widget may be disposed
  _data = data;
  notifyListeners();
}
```

## Docker Multi-Service Orchestration

**Service startup** (from [docker-compose.yml](../docker-compose.yml)):
```bash
docker-compose up -d       # Start all services
docker-compose logs -f backend   # Watch backend logs
docker-compose down        # Stop all services
```

**Service dependencies**:
```
Flutter (port 8080) → depends_on → Backend (port 3000) → depends_on → MongoDB (port 27017)
```

**Backend healthcheck** (from docker-compose.yml):
```bash
curl http://localhost:3000/api/v1/health  # Note /api/v1 prefix
```

**Flutter in Docker gotchas**:
- Uses production build (`flutter build web`), served by nginx
- Hot reload **does not work** - use local `flutter run` for development
- Backend connection: nginx proxies `/api` to `http://backend:3000/api`

## Integration Patterns

### API Response Format

All backend endpoints return consistent structure (enforced by HttpExceptionFilter):

**Success**:
```json
{ "data": {...}, "statusCode": 200 }
```

**Error**:
```json
{
  "statusCode": 400,
  "timestamp": "2024-01-01T12:00:00.000Z",
  "path": "/api/v1/auth/signup",
  "method": "POST",
  "error": "Bad Request",
  "message": "Email already exists"
}
```

**Flutter error handling**:
```dart
try {
  final response = await http.post(/* ... */);
  if (response.statusCode >= 400) {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Request failed');
  }
} catch (e) {
  // Show error to user
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
```

### Common Multi-Component Tasks

**Adding a new API endpoint with Flutter integration**:

1. **Backend** - Generate resource:
   ```bash
   cd backend
   nest g resource feature-name
   ```

2. **Add OpenAPI docs**:
   ```typescript
   @ApiTags('feature-name')
   @ApiBearerAuth('JWT-auth')
   @ApiOperation({ summary: 'Describe what this does' })
   ```

3. **Flutter constants** - Add endpoint to [constants.dart](../frontend/lib/utils/constants.dart):
   ```dart
   static const String featureEndpoint = '/api/v1/feature-name';
   ```

4. **Flutter service** - Create `lib/services/feature_service.dart`:
   ```dart
   class FeatureService {
     final Future<String?> Function() getToken;
     FeatureService({required this.getToken});
     
     Future<List<Item>> getItems() async {
       final token = await getToken();
       // HTTP call...
     }
   }
   ```

5. **Flutter provider** (if needed) - Add to [main.dart](../frontend/lib/main.dart):
   ```dart
   ChangeNotifierProvider(create: (_) => FeatureProvider()),
   ```

**Adding a new user role**:

1. Update enum in [user.schema.ts](../backend/src/users/schemas/user.schema.ts)
2. Add to allowed signup roles in [signup.dto.ts](../backend/src/auth/dto/signup.dto.ts) (if self-service)
3. Update [constants.dart](../frontend/lib/utils/constants.dart) helper methods:
   ```dart
   static bool isNewRole(String? role) => role == 'new_role';
   ```
4. Add role-based routing in [router.dart](../frontend/lib/utils/router.dart)

## Key Files Reference

### Backend
- [main.ts](../backend/src/main.ts) - App bootstrap, CORS, Swagger, global middleware
- [app.module.ts](../backend/src/app.module.ts) - All module imports, rate limiting config
- [auth.service.ts](../backend/src/auth/auth.service.ts) - Email verification, JWT, org creation
- [user.schema.ts](../backend/src/users/schemas/user.schema.ts) - User model with all roles
- [organization.controller.ts](../backend/src/organization/organization.controller.ts) - Multi-tenancy endpoints

### Frontend
- [main.dart](../frontend/lib/main.dart) - App entry, Provider hierarchy, theme
- [router.dart](../frontend/lib/utils/router.dart) - GoRouter config, role-based redirects
- [constants.dart](../frontend/lib/utils/constants.dart) - **Update `baseUrl` for deployment**
- [auth_provider.dart](../frontend/lib/providers/auth_provider.dart) - Auth state + token management
- [auth_service.dart](../frontend/lib/services/auth_service.dart) - Secure storage, API calls

### DevOps
- [docker-compose.yml](../docker-compose.yml) - Multi-service orchestration
- [init-mongo.js](../backend/init-mongo.js) - MongoDB index creation
- [backend/Dockerfile](../backend/Dockerfile) - NestJS production build
- [frontend/Dockerfile](../frontend/Dockerfile) - Flutter web build + nginx

## Common Gotchas

1. **Backend global prefix**: All endpoints start with `/api/v1`, not `/`. Healthcheck is `/api/v1/health`.

2. **MongoDB connection string**: Use `mongodb://mongodb:27017` in Docker, `mongodb://localhost:27017` locally. Atlas in production.

3. **CORS**: Backend allows all `localhost` origins in development. Add production origin to `CORS_ORIGIN` env var.

4. **Admin creation**: Admin users **must** be created via direct DB insertion. Never expose admin signup via API (security).

5. **Flutter hot reload**: Doesn't work in Docker. Use `flutter run` locally for development.

6. **SendGrid verification**: Email sending fails silently if sender not verified at https://app.sendgrid.com/settings/sender_auth/senders

7. **JWT storage**: Flutter uses `flutter_secure_storage` (secure). Web dashboard uses `localStorage` (XSS vulnerable).

8. **Provider async operations**: Always check `mounted` before `notifyListeners()` or using context.

9. **Physical device testing**: Change `baseUrl` in constants.dart to host machine IP. Backend must bind to `0.0.0.0`.

10. **Cloudinary for organization creation**: While Cloudinary is optional for general image uploads (community posts, profiles) and service gracefully degrades, it is **REQUIRED** for organization leader signup. Organization certificate PDF upload is mandatory and uses Cloudinary. Without Cloudinary configured, organization_leader signup will fail.
