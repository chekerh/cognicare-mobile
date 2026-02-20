import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';
import { User, UserSchema } from '../users/schemas/user.schema';
import {
  EmailVerification,
  EmailVerificationSchema,
} from './schemas/email-verification.schema';
import { MailModule } from '../mail/mail.module';
import { OrganizationModule } from '../organization/organization.module';
import {
  Organization,
  OrganizationSchema,
} from '../organization/schemas/organization.schema';
import {
  PendingOrganization,
  PendingOrganizationSchema,
} from '../organization/schemas/pending-organization.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import {
  FamilyMember,
  FamilyMemberSchema,
} from './schemas/family-member.schema';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { OrgScanAiModule } from '../orgScanAi/orgScanAi.module';

@Module({
  imports: [
    ConfigModule,
    PassportModule,
    MailModule,
    OrganizationModule,
    CloudinaryModule,
    OrgScanAiModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret:
          configService.get<string>('JWT_SECRET') || 'fallback-secret-key',
        signOptions: {
          expiresIn: 3600, // 1 hour in seconds
        },
      }),
      inject: [ConfigService],
    }),
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: EmailVerification.name, schema: EmailVerificationSchema },
      { name: Organization.name, schema: OrganizationSchema },
      { name: PendingOrganization.name, schema: PendingOrganizationSchema },
      { name: Child.name, schema: ChildSchema },
      { name: FamilyMember.name, schema: FamilyMemberSchema },
    ]),
  ],
  providers: [AuthService, JwtStrategy],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
