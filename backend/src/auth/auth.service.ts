import { Injectable, ConflictException, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from '../users/schemas/user.schema';
import { EmailVerification, EmailVerificationDocument } from './schemas/email-verification.schema';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { MailService } from '../mail/mail.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(EmailVerification.name) private emailVerificationModel: Model<EmailVerificationDocument>,
    private jwtService: JwtService,
    private configService: ConfigService,
    private mailService: MailService,
  ) {}

  private generateTokens(user: UserDocument) {
    const payload = { email: user.email, sub: user._id, role: user.role };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });
    
    return { accessToken, refreshToken };
  }

  private async hashRefreshToken(refreshToken: string): Promise<string> {
    const saltRounds = 10;
    return bcrypt.hash(refreshToken, saltRounds);
  }

  async signup(signupDto: SignupDto): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const { email, password, verificationCode, ...userData } = signupDto;

    // Prevent admin role creation through signup
    // This check is redundant due to DTO validation, but kept as defense in depth
    if ((userData.role as string) === 'admin') {
      throw new BadRequestException('Admin accounts can only be created by system administrators');
    }

    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Verify the email verification code
    const verification = await this.emailVerificationModel.findOne({ email }).exec();

    if (!verification) {
      throw new BadRequestException(
        'Email verification required. Please request a verification code first.',
      );
    }

    if (new Date() > verification.expiresAt) {
      await this.emailVerificationModel.deleteOne({ email });
      throw new BadRequestException('Verification code has expired. Please request a new code.');
    }

    const isValidCode = await bcrypt.compare(verificationCode, verification.code);
    if (!isValidCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Delete the verification record
    await this.emailVerificationModel.deleteOne({ email });

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const user = new this.userModel({
      ...userData,
      email,
      passwordHash,
    });

    await user.save();

    // Generate tokens
    const { accessToken, refreshToken } = this.generateTokens(user);

    // Hash and store refresh token
    const hashedRefreshToken = await this.hashRefreshToken(refreshToken);
    user.refreshToken = hashedRefreshToken;
    await user.save();

    return {
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profilePic: user.profilePic,
        createdAt: user.createdAt,
      },
    };
  }

  async login(loginDto: LoginDto): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const { email, password } = loginDto;

    // Find user by email
    const user = await this.userModel.findOne({ email });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate tokens
    const { accessToken, refreshToken } = this.generateTokens(user);

    // Hash and store refresh token
    const hashedRefreshToken = await this.hashRefreshToken(refreshToken);
    user.refreshToken = hashedRefreshToken;
    await user.save();

    return {
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profilePic: user.profilePic,
        createdAt: user.createdAt,
      },
    };
  }

  async refreshTokens(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // Verify refresh token
      const payload = this.jwtService.verify(refreshToken);
      
      // Find user
      const user = await this.userModel.findById(payload.sub);
      if (!user || !user.refreshToken) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Verify stored refresh token matches
      const refreshTokenMatches = await bcrypt.compare(refreshToken, user.refreshToken);
      if (!refreshTokenMatches) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Generate new tokens
      const tokens = this.generateTokens(user);

      // Hash and store new refresh token
      const hashedRefreshToken = await this.hashRefreshToken(tokens.refreshToken);
      user.refreshToken = hashedRefreshToken;
      await user.save();

      return tokens;
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string): Promise<void> {
    await this.userModel.findByIdAndUpdate(userId, { refreshToken: undefined });
  }

  async invalidateRefreshToken(userId: string): Promise<void> {
    // Called when email or password changes
    await this.userModel.findByIdAndUpdate(userId, { refreshToken: undefined });
  }

  async getProfile(userId: string): Promise<any> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profilePic: user.profilePic,
      createdAt: user.createdAt,
    };
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.userModel.findOne({ email });
    
    // Don't reveal if email exists or not for security
    if (!user) {
      return;
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash the code before storing
    const hashedCode = await bcrypt.hash(code, 10);
    
    // Set expiration to 10 minutes from now
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    user.passwordResetCode = hashedCode;
    user.passwordResetExpires = expiresAt;
    await user.save();

    // Send email with the plain code
    await this.mailService.sendVerificationCode(email, code);
  }

  async verifyResetCode(email: string, code: string): Promise<boolean> {
    const user = await this.userModel.findOne({ email });
    
    if (!user || !user.passwordResetCode || !user.passwordResetExpires) {
      throw new UnauthorizedException('Invalid or expired verification code');
    }

    // Check if code is expired
    if (new Date() > user.passwordResetExpires) {
      user.passwordResetCode = undefined;
      user.passwordResetExpires = undefined;
      await user.save();
      throw new UnauthorizedException('Verification code has expired');
    }

    // Verify the code
    const isValidCode = await bcrypt.compare(code, user.passwordResetCode);
    
    if (!isValidCode) {
      throw new UnauthorizedException('Invalid verification code');
    }

    return true;
  }

  async resetPassword(email: string, code: string, newPassword: string): Promise<void> {
    // First verify the code
    await this.verifyResetCode(email, code);

    const user = await this.userModel.findOne({ email });
    
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password and clear reset code
    user.passwordHash = passwordHash;
    user.passwordResetCode = undefined;
    user.passwordResetExpires = undefined;
    user.refreshToken = undefined; // Invalidate all sessions
    await user.save();
  }

  async sendVerificationCode(email: string): Promise<void> {
    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash the code before storing
    const hashedCode = await bcrypt.hash(code, 10);
    
    // Set expiration to 10 minutes from now
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    // Delete any existing verification for this email
    await this.emailVerificationModel.deleteMany({ email });

    // Create new verification record
    const verification = new this.emailVerificationModel({
      email,
      code: hashedCode,
      expiresAt,
      verified: false,
    });
    await verification.save();

    // Send email with the plain code
    await this.mailService.sendVerificationCode(email, code);
  }

  async verifyEmailCode(email: string, code: string): Promise<boolean> {
    const verification = await this.emailVerificationModel.findOne({ email }).exec();
    
    if (!verification) {
      throw new BadRequestException('No verification code found for this email');
    }

    if (new Date() > verification.expiresAt) {
      await this.emailVerificationModel.deleteOne({ email });
      throw new BadRequestException('Verification code has expired');
    }

    const isValidCode = await bcrypt.compare(code, verification.code);
    
    if (!isValidCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Mark as verified (don't delete yet - needed for signup)
    verification.verified = true;
    await verification.save();

    return true;
  }
}