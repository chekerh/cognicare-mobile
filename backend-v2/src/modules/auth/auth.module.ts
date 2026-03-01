/**
 * Auth Module
 */
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';

// Domain
import { EMAIL_VERIFICATION_REPOSITORY_TOKEN } from './domain/repositories/email-verification.repository.interface';
import { REFRESH_TOKEN_REPOSITORY_TOKEN } from './domain/repositories/refresh-token.repository.interface';

// Infrastructure - Schemas
import { EmailVerificationMongoSchema, EmailVerificationSchema } from './infrastructure/persistence/mongo/email-verification.schema';
import { RefreshTokenMongoSchema, RefreshTokenSchema } from './infrastructure/persistence/mongo/refresh-token.schema';

// Infrastructure - Repositories
import { EmailVerificationMongoRepository } from './infrastructure/persistence/mongo/email-verification.mongo-repository';
import { RefreshTokenMongoRepository } from './infrastructure/persistence/mongo/refresh-token.mongo-repository';

// Infrastructure - Strategies
import { JwtStrategy } from './infrastructure/strategies/jwt.strategy';

// Application - Use Cases
import { SendVerificationCodeUseCase } from './application/use-cases/send-verification-code.use-case';
import { SignupUseCase } from './application/use-cases/signup.use-case';
import { LoginUseCase } from './application/use-cases/login.use-case';

// Interface - Controllers
import { AuthController } from './interface/http/auth.controller';

// Other modules
import { UsersModule } from '../users/users.module';
import { OrganizationModule } from '../organization/organization.module';

@Module({
  imports: [
    ConfigModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET') || 'default-secret-change-in-production',
        signOptions: {
          expiresIn: parseInt(configService.get<string>('JWT_EXPIRATION') || '3600', 10),
        },
      }),
    }),
    MongooseModule.forFeature([
      { name: EmailVerificationMongoSchema.name, schema: EmailVerificationSchema },
      { name: RefreshTokenMongoSchema.name, schema: RefreshTokenSchema },
    ]),
    UsersModule,
    OrganizationModule,
  ],
  controllers: [AuthController],
  providers: [
    // Repositories
    {
      provide: EMAIL_VERIFICATION_REPOSITORY_TOKEN,
      useClass: EmailVerificationMongoRepository,
    },
    {
      provide: REFRESH_TOKEN_REPOSITORY_TOKEN,
      useClass: RefreshTokenMongoRepository,
    },
    // Strategies
    JwtStrategy,
    // Use Cases
    SendVerificationCodeUseCase,
    SignupUseCase,
    LoginUseCase,
  ],
  exports: [
    JwtModule,
    PassportModule,
    JwtStrategy,
  ],
})
export class AuthModule {}
