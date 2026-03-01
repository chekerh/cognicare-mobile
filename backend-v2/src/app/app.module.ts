/**
 * App Module - Root application module
 * Clean Architecture root composition
 */
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

// Infrastructure
import { DatabaseModule } from '../infrastructure/database/database.module';

// Feature Modules
import { AuthModule } from '../modules/auth/auth.module';
import { UsersModule } from '../modules/users/users.module';
import { OrganizationModule } from '../modules/organization/organization.module';
import { ChildrenModule } from '../modules/children/children.module';

// Shared
import { JwtAuthGuard } from '../shared/guards/jwt-auth.guard';

// App Controllers
import { HealthController } from './health.controller';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Rate Limiting
    ThrottlerModule.forRoot([{
      ttl: parseInt(process.env.THROTTLE_TTL || '60000', 10),
      limit: parseInt(process.env.THROTTLE_LIMIT || '10', 10),
    }]),

    // Database
    DatabaseModule,

    // Feature Modules
    AuthModule,
    UsersModule,
    OrganizationModule,
    ChildrenModule,
  ],
  controllers: [HealthController],
  providers: [
    // Global JWT Auth Guard (use @Public() decorator to skip)
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    // Global Rate Limiting
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
