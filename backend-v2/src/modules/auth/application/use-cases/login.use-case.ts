/**
 * Login Use Case - Application Layer
 */
import { Inject, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { JwtService } from '@nestjs/jwt';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok, err } from '../../../../core/application/result';
import { IUserRepository, USER_REPOSITORY_TOKEN } from '../../../users/domain/repositories/user.repository.interface';
import { UserEntity } from '../../../users/domain/entities/user.entity';
import { AuthResponseDto, UserResponseDto } from '../dto/auth.dto';

export interface LoginInput {
  email: string;
  password: string;
}

@Injectable()
export class LoginUseCase implements IUseCase<LoginInput, Result<AuthResponseDto, string>> {
  constructor(
    @Inject(USER_REPOSITORY_TOKEN)
    private readonly userRepo: IUserRepository,
    private readonly jwtService: JwtService,
  ) {}

  async execute(input: LoginInput): Promise<Result<AuthResponseDto, string>> {
    const email = input.email.toLowerCase().trim();

    // 1. Find user
    const user = await this.userRepo.findByEmail(email);
    if (!user) {
      return err('Invalid email or password');
    }

    // 2. Verify password
    const isValid = await bcrypt.compare(input.password, user.passwordHash);
    if (!isValid) {
      return err('Invalid email or password');
    }

    // 3. Check email verification
    if (!user.isEmailVerified) {
      return err('Please verify your email before logging in');
    }

    // 4. Generate tokens
    const tokens = this.generateTokens(user);

    return ok({
      ...tokens,
      user: this.mapUserToResponse(user),
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
