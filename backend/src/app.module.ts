import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TerminusModule } from '@nestjs/terminus';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { HealthModule } from './health/health.module';
import { MailModule } from './mail/mail.module';
import { OrganizationModule } from './organization/organization.module';
import { CommunityModule } from './community/community.module';
import { MarketplaceModule } from './marketplace/marketplace.module';
import { ConversationsModule } from './conversations/conversations.module';
import { AvailabilitiesModule } from './availabilities/availabilities.module';
import { ChildrenModule } from './children/children.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';

@Module({
  imports: [
    // Configuration module
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Rate limiting
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minute
        limit: 10, // 10 requests per minute for general routes
      },
    ]),

    // Health checks
    TerminusModule,

    // Application modules
    DatabaseModule,
    MailModule,
    AuthModule,
    UsersModule,
    HealthModule,
    OrganizationModule,
    CommunityModule,
    MarketplaceModule,
    ConversationsModule,
    AvailabilitiesModule,
    ChildrenModule,
    CloudinaryModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
