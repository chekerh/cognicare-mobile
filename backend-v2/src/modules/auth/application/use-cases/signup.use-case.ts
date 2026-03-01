/**
 * Signup Use Case - Application Layer
 */
import { Inject, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok, err } from '../../../../core/application/result';
import { IEmailVerificationRepository, EMAIL_VERIFICATION_REPOSITORY_TOKEN } from '../../domain/repositories/email-verification.repository.interface';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '../../../users/domain/repositories/user.repository.interface';
import { IOrganizationRepository, ORGANIZATION_REPOSITORY_TOKEN } from '../../../organization/domain/repositories/organization.repository.interface';
import { UserEntity, UserRole } from '../../../users/domain/entities/user.entity';
import { OrganizationEntity } from '../../../organization/domain/entities/organization.entity';
import { SignupDto, AuthResponseDto, UserResponseDto } from '../dto/auth.dto';
import { JwtService } from '@nestjs/jwt';

export interface SignupInput extends SignupDto {
  certificateBuffer?: Buffer;
  certificateMimetype?: string;
}

export interface SignupOutput {
  auth?: AuthResponseDto;
  pendingApproval?: boolean;
  message: string;
}

@Injectable()
export class SignupUseCase implements IUseCase<SignupInput, Result<SignupOutput, string>> {
  constructor(
    @Inject(EMAIL_VERIFICATION_REPOSITORY_TOKEN)
    private readonly verificationRepo: IEmailVerificationRepository,
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepo: IUserRepository,
    @Inject(ORGANIZATION_REPOSITORY_TOKEN)
    private readonly orgRepo: IOrganizationRepository,
    private readonly jwtService: JwtService,
  ) {}

  async execute(input: SignupInput): Promise<Result<SignupOutput, string>> {
    const email = input.email.toLowerCase().trim();

    // 1. Verify the code
    const verification = await this.verificationRepo.findByEmail(email);
    if (!verification) {
      return err('Verification code not found. Please request a new code.');
    }

    if (!verification.verifyCode(input.verificationCode)) {
      return err('Invalid or expired verification code');
    }

    // 2. Check if email already exists
    const existingUser = await this.userRepo.findByEmail(email);
    if (existingUser) {
      return err('Email already registered');
    }

    // 3. Validate organization leader requirements
    if (input.role === 'organization_leader') {
      if (!input.organizationName) {
        return err('Organization name is required for organization leader');
      }
      if (!input.certificateBuffer) {
        return err('Certificate PDF is required for organization leader');
      }
      if (input.certificateMimetype !== 'application/pdf') {
        return err('Certificate must be a PDF file');
      }
      // TODO: Validate PDF magic bytes
    }

    // 4. Hash password
    const bcryptRounds = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);
    const passwordHash = await bcrypt.hash(input.password, bcryptRounds);

    // 5. Create user entity
    const user = UserEntity.create({
      email,
      passwordHash,
      role: input.role as UserRole,
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      isEmailVerified: true,
    });

    // 6. Save user
    const savedUser = await this.userRepo.save(user);

    // 7. Delete verification code
    await this.verificationRepo.deleteByEmail(email);

    // 8. Handle organization leader
    if (input.role === 'organization_leader') {
      // TODO: Upload certificate to Cloudinary
      const certificateUrl = 'pending-upload';

      // Create organization
      const org = OrganizationEntity.create({
        name: input.organizationName!,
        leaderId: savedUser.id,
        certificateUrl,
      });
      await this.orgRepo.save(org);

      // Update user with organization ID
      savedUser.assignToOrganization(org.id);
      await this.userRepo.save(savedUser);

      // TODO: Trigger fraud analysis

      return ok({
        pendingApproval: true,
        message: 'Account created. Your organization is pending approval.',
      });
    }

    // 9. Generate tokens for non-org-leader users
    const tokens = this.generateTokens(savedUser);

    return ok({
      auth: {
        ...tokens,
        user: this.mapUserToResponse(savedUser),
      },
      message: 'Account created successfully',
    });
  }

  private generateTokens(user: UserEntity): { accessToken: string; refreshToken: string } {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    return { accessToken, refreshToken };
  }

  private mapUserToResponse(user: UserEntity): UserResponseDto {
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      profileImageUrl: user.profileImageUrl,
      organizationId: user.organizationId,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt,
    };
  }
}
