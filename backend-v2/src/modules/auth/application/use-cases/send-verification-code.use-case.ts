/**
 * Send Verification Code Use Case - Application Layer
 */
import { Inject, Injectable } from '@nestjs/common';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok, err } from '../../../../core/application/result';
import { IEmailVerificationRepository, EMAIL_VERIFICATION_REPOSITORY_TOKEN } from '../../domain/repositories/email-verification.repository.interface';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '../../../users/domain/repositories/user.repository.interface';
import { EmailVerificationEntity } from '../../domain/entities/email-verification.entity';

export interface SendVerificationCodeInput {
  email: string;
}

export interface SendVerificationCodeOutput {
  message: string;
  // In dev mode, we may return the code for testing
  code?: string;
}

@Injectable()
export class SendVerificationCodeUseCase implements IUseCase<SendVerificationCodeInput, Result<SendVerificationCodeOutput, string>> {
  constructor(
    @Inject(EMAIL_VERIFICATION_REPOSITORY_TOKEN)
    private readonly verificationRepo: IEmailVerificationRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepo: IUserRepository,
  ) {}

  async execute(input: SendVerificationCodeInput): Promise<Result<SendVerificationCodeOutput, string>> {
    const email = input.email.toLowerCase().trim();

    // Check if email already exists
    const existingUser = await this.userRepo.findByEmail(email);
    if (existingUser) {
      return err('Email already registered');
    }

    // Generate code and create verification entity
    const code = EmailVerificationEntity.generateCode();
    const verification = EmailVerificationEntity.create(email, code, 10);

    // Save (this will delete any existing verification for this email)
    await this.verificationRepo.save(verification);

    // TODO: Send email via mail service
    // For now, return code in development
    const isDev = process.env.NODE_ENV !== 'production';

    return ok({
      message: 'Verification code sent to email',
      code: isDev ? code : undefined,
    });
  }
}
