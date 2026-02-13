import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import * as compression from 'compression';
import { join } from 'path';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security headers (cross-origin allow so images can be loaded from app)
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  // Serve uploaded files (e.g. profile pictures, post images, voice .m4a) at /uploads
  const uploadsPath = join(process.cwd(), 'uploads');
  const express = await import('express');
  app.use(
    '/uploads',
    express.default.static(uploadsPath, {
      index: false,
      setHeaders: (
        res: { setHeader: (name: string, value: string) => void },
        path: string,
      ) => {
        if (path.endsWith('.m4a')) res.setHeader('Content-Type', 'audio/mp4');
      },
    }),
  );

  // Enable compression
  // eslint-disable-next-line @typescript-eslint/no-unsafe-call
  app.use(compression.default());

  // Enable CORS for Flutter app and web
  const corsOriginEnv = process.env.CORS_ORIGIN;
  const allowedOrigins = [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8080',
    'http://localhost:54200', // Flutter web dev server
    'http://localhost:54201',
    'http://localhost:54202',
    corsOriginEnv,
  ].filter(Boolean);

  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin) {
        callback(null, true);
        return;
      }

      // In development, allow localhost and 127.0.0.1 (Flutter web uses random ports)
      if (
        process.env.NODE_ENV !== 'production' &&
        (origin.startsWith('http://localhost:') ||
          origin.startsWith('http://127.0.0.1:'))
      ) {
        callback(null, true);
        return;
      }

      // Allow multiple origins from CORS_ORIGIN (comma-separated on Render)
      if (corsOriginEnv) {
        const list = corsOriginEnv
          .split(',')
          .map((o) => o.trim())
          .filter(Boolean);
        if (list.indexOf(origin) !== -1) {
          callback(null, true);
          return;
        }
      }

      // Check against allowed origins list
      if (allowedOrigins.indexOf(origin) !== -1) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
    allowedHeaders: 'Content-Type,Authorization,Accept',
  });

  // Global prefix for API versioning
  app.setGlobalPrefix('api/v1');

  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Global interceptors
  app.useGlobalInterceptors(new LoggingInterceptor());

  // Enable global validation pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger/OpenAPI documentation
  const config = new DocumentBuilder()
    .setTitle('CogniCare API')
    .setDescription(
      'Personalized cognitive health and development platform API',
    )
    .setVersion('1.0')
    .addTag('auth', 'Authentication endpoints')
    .addTag('users', 'User management')
    .addTag('health', 'Health checks')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-auth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  // Graceful shutdown
  app.enableShutdownHooks();

  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  console.log(`🚀 CogniCare API is running on: http://localhost:${port}`);
  console.log(`📚 Swagger documentation: http://localhost:${port}/api`);
}
void bootstrap();
