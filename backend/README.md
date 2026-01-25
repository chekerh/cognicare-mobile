# CogniCare Backend API

A comprehensive NestJS API for the CogniCare cognitive health platform, featuring JWT authentication, MongoDB integration, and comprehensive API documentation.

## 🚀 Features

- **JWT Authentication** - Secure token-based authentication
- **MongoDB Integration** - NoSQL database with Mongoose ODM
- **Rate Limiting** - Protection against abuse with configurable limits
- **Swagger Documentation** - Interactive API documentation
- **Health Checks** - Application and database health monitoring
- **Global Error Handling** - Consistent error responses
- **Request Logging** - Comprehensive HTTP request logging
- **Security Headers** - Helmet.js for security headers
- **Response Compression** - Gzip compression for better performance
- **Input Validation** - Class-validator with transformation
- **API Versioning** - Versioned API endpoints

## 🛠️ Tech Stack

- **Framework**: NestJS
- **Language**: TypeScript
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT with Passport.js
- **Validation**: class-validator & class-transformer
- **Documentation**: Swagger/OpenAPI
- **Security**: Helmet, CORS, Rate Limiting
- **Testing**: Jest
- **Linting**: ESLint

## 📋 Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- MongoDB (local or cloud instance)

## 🚀 Installation

1. **Clone and install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Environment Setup:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start MongoDB:**
   ```bash
   # Local MongoDB
   mongod

   # Or use MongoDB Atlas (cloud)
   ```

4. **Run the application:**
   ```bash
   # Development
   npm run start:dev

   # Production
   npm run build
   npm run start:prod
   ```

## ⚙️ Environment Configuration

Create a `.env` file with the following variables:

```env
# Application
NODE_ENV=development
PORT=3000

# Database
MONGODB_URI=mongodb://localhost:27017/cognicare

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRATION=1h

# CORS
CORS_ORIGIN=http://localhost:3000

# Rate Limiting
THROTTLE_TTL=60000
THROTTLE_LIMIT=10

# Security
BCRYPT_ROUNDS=12
```

## 📚 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:3000/api
- **ReDoc**: http://localhost:3000/api-json

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## 🏥 Health Checks

Check application health at: `GET /api/v1/health`

## 📡 API Endpoints

### Authentication
- `POST /api/v1/auth/signup` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/profile` - Get user profile (protected)

### Health
- `GET /api/v1/health` - Application health check

## 🧪 Testing

```bash
# Run tests
npm run test

# Run tests with coverage
npm run test:cov

# Run e2e tests
npm run test:e2e
```

## 📦 Build & Deployment

```bash
# Build for production
npm run build

# Start production server
npm run start:prod
```

## 🛡️ Security Features

- **Helmet.js**: Security headers
- **CORS**: Configurable cross-origin requests
- **Rate Limiting**: Prevents abuse
- **Input Validation**: Comprehensive validation
- **JWT Expiration**: Token-based authentication
- **Password Hashing**: bcrypt with configurable rounds

## 🔍 Monitoring & Logging

- **Request Logging**: All HTTP requests are logged
- **Error Logging**: Structured error logging
- **Health Checks**: Database and application health monitoring

## 📝 Development Guidelines

### Code Style
- Use TypeScript for all new code
- Follow ESLint configuration
- Use Prettier for code formatting

### API Design
- RESTful endpoints with proper HTTP methods
- Consistent response format
- Comprehensive error handling
- Swagger documentation for all endpoints

### Database
- Use Mongoose schemas for data validation
- Implement proper indexes for performance
- Use transactions for critical operations

## 🤝 Contributing

1. Follow the existing code style
2. Add tests for new features
3. Update documentation
4. Create meaningful commit messages

## 📄 License

This project is part of the CogniCare platform.

---

**API Base URL**: `http://localhost:3000/api/v1`
**Swagger Documentation**: `http://localhost:3000/api`