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
import { GamificationModule } from './gamification/gamification.module';
import { VolunteersModule } from './volunteers/volunteers.module';
import { CoursesModule } from './courses/courses.module';
import { CertificationTestModule } from './certification-test/certification-test.module';
import { NutritionModule } from './nutrition/nutrition.module';
import { CallsModule } from './calls/calls.module';
import { EngagementModule } from './engagement/engagement.module';
import { DonationsModule } from './donations/donations.module';
import { PaypalModule } from './paypal/paypal.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OrgScanAiModule } from './orgScanAi/orgScanAi.module';
import { ImportModule } from './import/import.module';

import { SpecializedPlansModule } from './specialized-plans/specialized-plans.module';
import { ProgressAiModule } from './progress-ai/progress-ai.module';
import { ChatbotModule } from './chatbot/chatbot.module';
import { HealthcareCabinetsModule } from './healthcare-cabinets/healthcare-cabinets.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { TrainingModule } from './training/training.module';

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
    GamificationModule,
    VolunteersModule,
    CoursesModule,
    CertificationTestModule,
    NutritionModule,
    CallsModule,
    EngagementModule,
    DonationsModule,
    PaypalModule,
    NotificationsModule,
    OrgScanAiModule,
    ImportModule,
    SpecializedPlansModule,
    ProgressAiModule,
    ChatbotModule,
    HealthcareCabinetsModule,
    IntegrationsModule,
    TrainingModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
