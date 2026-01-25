# CogniCare 🧠

A comprehensive cognitive health platform featuring a modern Flutter mobile app and a robust NestJS backend API. Designed for personalized cognitive development and healthcare management.

## 🚀 Features

### Frontend (Flutter)
- **Cross-platform**: iOS, Android, Web support
- **Multi-language**: English, French, Arabic (RTL)
- **Modern UI**: Material Design 3 with custom theme
- **Authentication**: JWT-based secure login/signup
- **Onboarding**: Interactive introduction flow
- **State Management**: Provider pattern
- **Secure Storage**: Encrypted JWT token storage

### Backend (NestJS)
- **RESTful API**: Versioned endpoints (`/api/v1`)
- **Authentication**: JWT with Passport.js
- **Database**: MongoDB with Mongoose ODM
- **Security**: Helmet, CORS, rate limiting
- **Documentation**: Swagger/OpenAPI interactive docs
- **Health Checks**: Application and database monitoring
- **Validation**: Class-validator with transformation
- **Logging**: Request/response logging
- **Compression**: Gzip response compression

## 🛠️ Tech Stack

- **Frontend**: Flutter, Dart, Provider, Go Router
- **Backend**: NestJS, Node.js, TypeScript, MongoDB
- **Authentication**: JWT, bcrypt
- **Documentation**: Swagger/OpenAPI
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions

## 📋 Prerequisites

- **Flutter**: 3.10.4+
- **Node.js**: 18+
- **MongoDB**: 7.0+
- **Docker**: 20.10+ (optional)

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Clone the repository
git clone <your-repo-url>
cd cognicare

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

**Services will be available at:**
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3000
- **API Docs**: http://localhost:3000/api

### Option 2: Manual Setup

#### Backend Setup
```bash
cd backend
npm install
cp .env.example .env  # Configure environment variables
npm run start:dev
```

#### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

#### Database Setup
```bash
# Install MongoDB locally or use MongoDB Atlas
mongod  # Start MongoDB service
```

## 📖 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/v1/auth/signup
Content-Type: application/json

{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "phone": "+1234567890",
  "role": "family"
}
```

#### Login User
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

#### Get Profile
```http
GET /api/v1/auth/profile
Authorization: Bearer <jwt-token>
```

### Health Check
```http
GET /api/v1/health
```

**Interactive API Documentation**: http://localhost:3000/api

## 🔧 Configuration

### Environment Variables

Create `.env` file in the backend directory:

```env
# Application
NODE_ENV=development
PORT=3000

# Database
MONGODB_URI=mongodb://localhost:27017/cognicare

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRATION=3600

# CORS
CORS_ORIGIN=http://localhost:3000

# Rate Limiting
THROTTLE_TTL=60000
THROTTLE_LIMIT=10

# Security
BCRYPT_ROUNDS=12
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm run test              # Unit tests
npm run test:e2e         # End-to-end tests
npm run test:cov         # Tests with coverage
```

### Frontend Tests
```bash
cd frontend
flutter test
flutter analyze
```

## 🚢 Deployment

### Production Build

#### Backend
```bash
cd backend
npm run build
npm run start:prod
```

#### Frontend
```bash
cd frontend
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

### Docker Deployment
```bash
# Build and run with Docker Compose
docker-compose -f docker-compose.yml up -d

# Or use the CI/CD pipeline (GitHub Actions)
```

## 📊 Monitoring

### Health Checks
- **Application Health**: `GET /api/v1/health`
- **Database Status**: MongoDB connection monitoring
- **Request Logging**: All HTTP requests logged
- **Error Tracking**: Structured error responses

### Metrics
- Response times
- Error rates
- Database connection status
- Rate limiting status

## 🔒 Security Features

- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: bcrypt with configurable rounds
- **Rate Limiting**: Prevents abuse (configurable limits)
- **Security Headers**: Helmet.js protection
- **CORS**: Configurable cross-origin policies
- **Input Validation**: Comprehensive request validation
- **SQL Injection Protection**: MongoDB/Mongoose ODM

## 🌍 Internationalization

The app supports multiple languages:
- **English** (en)
- **French** (fr)
- **Arabic** (ar) - RTL support

Language switching is handled automatically based on device locale.

## 🗂️ Project Structure

```
cognicare/
├── backend/                 # NestJS API server
│   ├── src/
│   │   ├── auth/           # Authentication module
│   │   ├── database/       # Database configuration
│   │   ├── health/         # Health checks
│   │   └── common/         # Shared utilities
│   ├── Dockerfile
│   └── package.json
├── frontend/                # Flutter mobile app
│   ├── lib/
│   │   ├── screens/        # UI screens
│   │   ├── providers/      # State management
│   │   ├── services/       # API services
│   │   ├── models/         # Data models
│   │   └── utils/          # Utilities
│   ├── Dockerfile
│   └── pubspec.yaml
├── docker-compose.yml       # Docker orchestration
├── .github/                # CI/CD workflows
└── README.md
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow existing code style and conventions
- Add tests for new features
- Update documentation
- Use meaningful commit messages
- Ensure all tests pass before submitting PR

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- NestJS team for the amazing framework
- Flutter team for the cross-platform framework
- MongoDB for the database solution
- All contributors and open-source projects used

---

**CogniCare** - Empowering cognitive health through technology 🧠✨