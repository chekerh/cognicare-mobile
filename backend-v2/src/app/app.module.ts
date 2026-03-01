/**
 * App Module - Root application module
 * Clean Architecture root composition
 */
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { ThrottlerModule, ThrottlerGuard } from "@nestjs/throttler";

// Infrastructure
import { DatabaseModule } from "@/infrastructure/database/database.module";

// Core Feature Modules
import { AuthModule } from "../modules/auth/auth.module";
import { UsersModule } from "../modules/users/users.module";
import { OrganizationModule } from "../modules/organization/organization.module";
import { ChildrenModule } from "../modules/children/children.module";

// Communication & Social
import { CommunityModule } from "../modules/community/community.module";
import { ConversationsModule } from "../modules/conversations/conversations.module";
import { NotificationsModule } from "../modules/notifications/notifications.module";
import { CallsModule } from "../modules/calls/calls.module";
import { ChatbotModule } from "../modules/chatbot/chatbot.module";

// Commerce & Donations
import { MarketplaceModule } from "../modules/marketplace/marketplace.module";
import { DonationsModule } from "../modules/donations/donations.module";
import { PaypalModule } from "../modules/paypal/paypal.module";

// Health & Therapy
import { HealthModule } from "../modules/health/health.module";
import { NutritionModule } from "../modules/nutrition/nutrition.module";
import { SpecializedPlansModule } from "../modules/specialized-plans/specialized-plans.module";
import { HealthcareCabinetsModule } from "../modules/healthcare-cabinets/healthcare-cabinets.module";

// Engagement & Gamification
import { GamificationModule } from "../modules/gamification/gamification.module";
import { EngagementModule } from "../modules/engagement/engagement.module";

// Learning & Volunteering
import { CoursesModule } from "../modules/courses/courses.module";
import { VolunteersModule } from "../modules/volunteers/volunteers.module";
import { TrainingModule } from "../modules/training/training.module";
import { CertificationTestModule } from "../modules/certification-test/certification-test.module";

// AI & Analysis
import { ProgressAiModule } from "../modules/progress-ai/progress-ai.module";
import { OrgScanAiModule } from "../modules/org-scan-ai/org-scan-ai.module";

// Infrastructure Services
import { CloudinaryModule } from "../modules/cloudinary/cloudinary.module";
import { MailModule } from "../modules/mail/mail.module";
import { AvailabilitiesModule } from "../modules/availabilities/availabilities.module";
import { IntegrationsModule } from "../modules/integrations/integrations.module";
import { ImportModule } from "../modules/import/import.module";

// Shared
import { JwtAuthGuard } from "../shared/guards/jwt-auth.guard";

// App Controllers
import { HealthController } from "./health.controller";

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [".env.local", ".env"],
    }),

    // Rate Limiting
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.THROTTLE_TTL || "60000", 10),
        limit: parseInt(process.env.THROTTLE_LIMIT || "10", 10),
      },
    ]),

    // Database
    DatabaseModule,

    // Infrastructure (global modules first)
    CloudinaryModule,
    MailModule,

    // Core Feature Modules
    AuthModule,
    UsersModule,
    OrganizationModule,
    ChildrenModule,

    // Communication & Social
    CommunityModule,
    ConversationsModule,
    NotificationsModule,
    CallsModule,
    ChatbotModule,

    // Commerce & Donations
    MarketplaceModule,
    DonationsModule,
    PaypalModule,

    // Health & Therapy
    HealthModule,
    NutritionModule,
    SpecializedPlansModule,
    HealthcareCabinetsModule,

    // Engagement & Gamification
    GamificationModule,
    EngagementModule,

    // Learning & Volunteering
    CoursesModule,
    VolunteersModule,
    TrainingModule,
    CertificationTestModule,

    // AI & Analysis
    ProgressAiModule,
    OrgScanAiModule,

    // Utilities
    AvailabilitiesModule,
    IntegrationsModule,
    ImportModule,
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
