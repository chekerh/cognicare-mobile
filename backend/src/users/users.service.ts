import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from './schemas/user.schema';
import { UpdateUserDto } from './dto/update-user.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { MailService } from '../mail/mail.service';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private mailService: MailService,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const { email, password, ...userData } = createUserDto;

    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new BadRequestException('User with this email already exists');
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user (admin-created users don't need email verification)
    const user = new this.userModel({
      ...userData,
      email,
      passwordHash,
    });

    await user.save();

    // Return user without passwordHash
    return this.findOne(user._id.toString());
  }

  async findAll(): Promise<User[]> {
    return this.userModel.find().select('-passwordHash').exec();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel
      .findById(id)
      .select('-passwordHash')
      .exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.userModel
      .findByIdAndUpdate(id, updateUserDto, { new: true })
      .select('-passwordHash')
      .exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();

    if (!result) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
  }

  async findByRole(
    role: 'family' | 'doctor' | 'volunteer' | 'admin',
  ): Promise<User[]> {
    return this.userModel.find({ role }).select('-passwordHash').exec();
  }

  /** List other family users (for starting conversations). Excludes current user. */
  async findFamilyUsers(excludeUserId: string): Promise<{ id: string; fullName: string; profilePic?: string }[]> {
    const users = await this.userModel
      .find({ role: 'family', _id: { $ne: excludeUserId } })
      .select('_id fullName profilePic')
      .sort({ fullName: 1 })
      .lean()
      .exec();
    return users.map((u: any) => ({
      id: u._id.toString(),
      fullName: u.fullName ?? '',
      profilePic: u.profilePic,
    }));
  }

  /** List healthcare professionals (any authenticated user, e.g. family can contact them). */
  async findHealthcareProfessionals(): Promise<User[]> {
    return this.userModel
      .find({
        role: {
          $in: [
            'doctor',
            'psychologist',
            'speech_therapist',
            'occupational_therapist',
          ],
        },
      })
      .select('-passwordHash')
      .sort({ fullName: 1 })
      .exec();
  }

  /** Consider user "online" if lastSeenAt is within the last 5 minutes. */
  async getPresence(userId: string): Promise<{ online: boolean }> {
    const user = await this.userModel
      .findById(userId)
      .select('lastSeenAt')
      .lean()
      .exec();
    if (!user || !user.lastSeenAt) {
      return { online: false };
    }
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    return { online: new Date(user.lastSeenAt) >= fiveMinutesAgo };
  }

  async updatePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.userModel.findById(userId).exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(
      currentPassword,
      user.passwordHash,
    );
    if (!isPasswordValid) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password and invalidate refresh token
    user.passwordHash = passwordHash;
    user.refreshToken = undefined;
    await user.save();
  }

  async updateEmail(
    userId: string,
    newEmail: string,
    password: string,
  ): Promise<User> {
    const user = await this.userModel.findById(userId).exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Password is incorrect');
    }

    // Check if new email already exists
    const existingUser = await this.userModel
      .findOne({ email: newEmail })
      .exec();
    if (existingUser && existingUser._id.toString() !== userId) {
      throw new Error('Email already in use');
    }

    // Update email and invalidate refresh token
    user.email = newEmail;
    user.refreshToken = undefined;
    await user.save();

    return this.findOne(userId);
  }

  async requestEmailChange(
    userId: string,
    newEmail: string,
    password: string,
  ): Promise<void> {
    const user = await this.userModel.findById(userId).exec();

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Password is incorrect');
    }

    // Check if new email already exists
    const existingUser = await this.userModel
      .findOne({ email: newEmail })
      .exec();
    if (existingUser && existingUser._id.toString() !== userId) {
      throw new BadRequestException('Email already in use');
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash the code before storing
    const hashedCode = await bcrypt.hash(code, 10);

    // Set expiration to 10 minutes from now
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    user.emailChangeCode = hashedCode;
    user.emailChangeExpires = expiresAt;
    user.pendingEmail = newEmail;
    await user.save();

    // Send email with the plain code to the NEW email address
    await this.mailService.sendVerificationCode(newEmail, code);
  }

  async verifyEmailChange(userId: string, code: string): Promise<User> {
    const user = await this.userModel.findById(userId).exec();

    if (
      !user ||
      !user.emailChangeCode ||
      !user.emailChangeExpires ||
      !user.pendingEmail
    ) {
      throw new BadRequestException('No pending email change request');
    }

    // Check if code is expired
    if (new Date() > user.emailChangeExpires) {
      user.emailChangeCode = undefined;
      user.emailChangeExpires = undefined;
      user.pendingEmail = undefined;
      await user.save();
      throw new BadRequestException('Verification code has expired');
    }

    // Verify the code
    const isValidCode = await bcrypt.compare(code, user.emailChangeCode);

    if (!isValidCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Update email and clear verification fields
    user.email = user.pendingEmail;
    user.emailChangeCode = undefined;
    user.emailChangeExpires = undefined;
    user.pendingEmail = undefined;
    user.refreshToken = undefined; // Invalidate all sessions
    await user.save();

    return this.findOne(userId);
  }
}
