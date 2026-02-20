import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from '../users/schemas/user.schema';
import {
  EmailVerification,
  EmailVerificationDocument,
} from './schemas/email-verification.schema';
import {
  Organization,
  OrganizationDocument,
} from '../organization/schemas/organization.schema';
import {
  PendingOrganization,
  PendingOrganizationDocument,
} from '../organization/schemas/pending-organization.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import {
  FamilyMember,
  FamilyMemberDocument,
} from './schemas/family-member.schema';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { MailService } from '../mail/mail.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { OrganizationService } from '../organization/organization.service';
import { FraudAnalysisService } from '../orgScanAi/fraud-analysis.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private cloudinary: CloudinaryService,
    @InjectModel(EmailVerification.name)
    private emailVerificationModel: Model<EmailVerificationDocument>,
    @InjectModel(Organization.name)
    private organizationModel: Model<OrganizationDocument>,
    @InjectModel(PendingOrganization.name)
    private pendingOrganizationModel: Model<PendingOrganizationDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(FamilyMember.name)
    private familyMemberModel: Model<FamilyMemberDocument>,
    private jwtService: JwtService,
    private configService: ConfigService,
    private mailService: MailService,
    private organizationService: OrganizationService,
    private readonly fraudAnalysisService: FraudAnalysisService,
  ) {}

  private generateTokens(user: UserDocument) {
    const payload = {
      email: user.email,
      sub: user._id.toString(),
      role: user.role,
    };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    return { accessToken, refreshToken };
  }

  private async hashRefreshToken(refreshToken: string): Promise<string> {
    const saltRounds = 10;
    return bcrypt.hash(refreshToken, saltRounds);
  }

  async signup(
    signupDto: SignupDto,
    certificatePdfBuffer?: Buffer,
  ): Promise<
    | { accessToken: string; refreshToken: string; user: any }
    | {
        requiresApproval: true;
        message: string;
        user: any;
        pendingOrganization: any;
      }
  > {
    const {
      email,
      password,
      verificationCode,
      organizationName,
      organizationDescription,
      ...userData
    } = signupDto;

    // Prevent admin role creation through signup
    // This check is redundant due to DTO validation, but kept as defense in depth
    if ((userData.role as string) === 'admin') {
      throw new BadRequestException(
        'Admin accounts can only be created by system administrators',
      );
    }

    // Check if user already exists
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Verify the email verification code
    const verification = await this.emailVerificationModel
      .findOne({ email })
      .exec();

    if (!verification) {
      throw new BadRequestException(
        'Email verification required. Please request a verification code first.',
      );
    }

    if (new Date() > verification.expiresAt) {
      await this.emailVerificationModel.deleteOne({ email });
      throw new BadRequestException(
        'Verification code has expired. Please request a new code.',
      );
    }

    const isValidCode = await bcrypt.compare(
      verificationCode,
      verification.code,
    );
    if (!isValidCode) {
      throw new BadRequestException('Invalid verification code');
    }

    // Delete the verification record
    await this.emailVerificationModel.deleteOne({ email });

    // For organization leaders, check if there's a previously rejected application
    if (userData.role === 'organization_leader') {
      const rejectedOrg = await this.pendingOrganizationModel
        .findOne({
          leaderEmail: email,
          status: 'rejected',
        })
        .sort({ createdAt: -1 });

      if (rejectedOrg) {
        const reason =
          rejectedOrg.rejectionReason ||
          'Not specified. Please contact support for details.';
        throw new BadRequestException(
          `A previous organization application from this email was rejected. Reason: ${reason}. Please contact support if you believe this is an error.`,
        );
      }
    }

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

    // If role is organization_leader, create pending organization request
    let pendingOrganization: any = null;
    if (userData.role === 'organization_leader') {
      // Certificate PDF is required for organization leaders
      if (!certificatePdfBuffer) {
        throw new BadRequestException(
          'Organization registration certificate (PDF) is required for organization leaders',
        );
      }

      const orgName = organizationName || `${user.fullName}'s Organization`;

      // Upload certificate PDF to Cloudinary
      let certificateUrl: string;
      try {
        console.log('[SIGNUP] Uploading certificate PDF to Cloudinary');
        certificateUrl = await this.cloudinary.uploadRawBuffer(
          certificatePdfBuffer,
          {
            folder: 'organization-certificates',
            publicId: `cert_${user._id.toString()}_${Date.now()}`,
            resourceType: 'raw',
          },
        );
        console.log('[SIGNUP] Certificate uploaded:', certificateUrl);
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';
        console.error('[SIGNUP] Failed to upload certificate:', errorMessage);
        throw new BadRequestException(
          'Failed to upload organization certificate. Please try again.',
        );
      }

      pendingOrganization =
        await this.organizationService.createPendingOrganization(
          orgName,
          user._id.toString(),
          organizationDescription,
          certificateUrl,
        );

      console.log(
        '[SIGNUP] Organization leader signup - NOT generating tokens',
      );
      console.log('[SIGNUP] Pending organization ID:', pendingOrganization._id);

      // Trigger AI fraud analysis with certificate PDF
      try {
        console.log('[SIGNUP] Triggering AI fraud analysis for certificate');
        const analysisInput = {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-call
          organizationId: pendingOrganization._id.toString(),
          pdfBuffer: certificatePdfBuffer,
          email: user.email,
          websiteDomain: undefined, // Optional field
          originalPdfPath: certificateUrl,
        };
        const fraudAnalysis =
          await this.fraudAnalysisService.analyzeOrganization(analysisInput);

        console.log(
          '[SIGNUP] Fraud analysis completed. Risk level:',
          fraudAnalysis.level,
          'Score:',
          fraudAnalysis.fraudRisk,
        );
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';
        console.error(
          '[SIGNUP] Failed to perform fraud analysis:',
          errorMessage,
        );
        // Don't fail signup if fraud analysis fails - admin can review manually
      }

      // For organization leaders, do NOT log them in until admin approves
      // Return a special response indicating they need to wait for approval
      return {
        requiresApproval: true,
        message:
          'Your organization request has been submitted successfully. An AI-powered fraud detection system has analyzed your certificate. Please wait for admin approval. You will receive an email notification once your request is reviewed.',
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
        },
        pendingOrganization: {
          id: pendingOrganization._id,
          organizationName: pendingOrganization.organizationName,
          status: pendingOrganization.status,
          createdAt: pendingOrganization.createdAt,
        },
      };
    }

    // Generate tokens for non-organization_leader roles
    const { accessToken, refreshToken } = this.generateTokens(user);

    // Hash and store refresh token
    const hashedRefreshToken = await this.hashRefreshToken(refreshToken);
    user.refreshToken = hashedRefreshToken;
    await user.save();

    // Send welcome email (non-blocking)
    this.mailService
      .sendWelcomeEmail(user.email, user.fullName)
      .catch((err) => console.error('Failed to send welcome email:', err));

    const userResponse: any = {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      organizationId: user.organizationId,
      profilePic: user.profilePic,
      createdAt: user.createdAt,
    };

    return {
      accessToken,
      refreshToken,
      user: userResponse,
    };
  }

  async login(
    loginDto: LoginDto,
  ): Promise<{ accessToken: string; refreshToken: string; user: any }> {
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

    // Check if account is confirmed (Specialist invitation flow)
    if (!user.isConfirmed) {
      throw new UnauthorizedException(
        'Your account is not confirmed. Please check your email and click the activation link to set your password.',
      );
    }

    // Check if organization leader has pending approval
    if (user.role === 'organization_leader') {
      console.log('[LOGIN] Organization leader attempting login:', user.email);

      // Check if user has an approved organization
      const organization = await this.organizationModel.findOne({
        leaderId: user._id,
      });

      console.log(
        '[LOGIN] Approved organization found:',
        organization ? 'YES' : 'NO',
      );

      if (!organization) {
        // Check if they have a pending request
        const pendingOrg = await this.pendingOrganizationModel.findOne({
          requestedBy: user._id,
          status: 'pending',
        });

        console.log(
          '[LOGIN] Pending organization found:',
          pendingOrg ? 'YES' : 'NO',
        );

        // Debug: Check ALL pending orgs for this user
        const allPendingOrgs = await this.pendingOrganizationModel.find({
          requestedBy: user._id,
        });
        console.log(
          '[LOGIN] All pending orgs for user:',
          allPendingOrgs.length,
        );
        if (allPendingOrgs.length > 0) {
          console.log(
            '[LOGIN] Pending org statuses:',
            allPendingOrgs.map((org) => org.status),
          );
        }

        if (pendingOrg) {
          throw new UnauthorizedException(
            'Your organization request is pending approval. You will receive an email notification once your request is reviewed.',
          );
        }

        // Check if they had a rejected request
        const rejectedOrg = await this.pendingOrganizationModel
          .findOne({
            requestedBy: user._id,
            status: 'rejected',
          })
          .sort({ createdAt: -1 });

        console.log(
          '[LOGIN] Rejected organization found:',
          rejectedOrg ? 'YES' : 'NO',
        );
        console.log('[LOGIN] User ID being checked:', String(user._id));
        console.log(
          '[LOGIN] Query criteria:',
          JSON.stringify({
            requestedBy: String(user._id),
            status: 'rejected',
          }),
        );

        if (rejectedOrg) {
          const reason =
            rejectedOrg.rejectionReason ||
            'Not specified. Please contact support for more details.';
          throw new UnauthorizedException(
            `Your organization request was rejected. Reason: ${reason}. You cannot log in with this account.`,
          );
        }

        // Also check by email (in case user account was deleted and recreated)
        const rejectedByEmail = await this.pendingOrganizationModel
          .findOne({
            leaderEmail: user.email,
            status: 'rejected',
          })
          .sort({ createdAt: -1 });

        console.log(
          '[LOGIN] Rejected organization by email found:',
          rejectedByEmail ? 'YES' : 'NO',
        );

        if (rejectedByEmail) {
          const reason =
            rejectedByEmail.rejectionReason ||
            'Not specified. Please contact support for more details.';
          throw new UnauthorizedException(
            `Your organization request was rejected. Reason: ${reason}. You cannot log in with this account. If you believe this is an error, please contact support.`,
          );
        }

        // No organization and no pending/rejected request
        // This could happen if the pending request was deleted or never created
        console.log(
          '[LOGIN] No organization/pending/rejected found - edge case',
        );
        throw new UnauthorizedException(
          'Your organization request is under review. You will receive an email notification once your request is reviewed. If you continue to experience issues, please contact support.',
        );
      }

      console.log('[LOGIN] Organization leader has approved organization');
    }

    // Generate tokens
    const { accessToken, refreshToken } = this.generateTokens(user);

    // Hash and store refresh token; update presence (online)
    const hashedRefreshToken = await this.hashRefreshToken(refreshToken);
    user.refreshToken = hashedRefreshToken;
    user.lastSeenAt = new Date();
    await user.save();

    const userResponse: any = {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profilePic: user.profilePic,
      createdAt: user.createdAt,
    };

    if (user.role === 'organization_leader') {
      const organization = await this.organizationModel
        .findOne({ leaderId: user._id })
        // Populate arrays from Organization document (NOT from User document)
        .populate('staffIds') // Fetch all staff users linked to this organization
        .populate('familyIds') // Fetch all family users linked to this organization
        .populate('childrenIds'); // Fetch all children linked to this organization

      console.log('Organization found:', organization ? 'YES' : 'NO');
      if (organization) {
        console.log('Organization ID:', organization._id);
        console.log('Organization Name:', organization.name);
        console.log('Staff IDs array:', organization.staffIds);
        console.log('Staff count:', organization.staffIds?.length || 0);
        console.log('Families count:', organization.familyIds?.length || 0);
        console.log('Children count:', organization.childrenIds?.length || 0);

        // Build clean arrays without circular references
        const staffArray = (organization.staffIds || []).map((staff: any) => ({
          id: staff._id,
          fullName: staff.fullName,
          email: staff.email,
          phone: staff.phone,
          role: staff.role,
          createdAt: staff.createdAt,
        }));

        const familiesArray = (organization.familyIds || []).map(
          (family: any) => ({
            id: family._id,
            fullName: family.fullName,
            email: family.email,
            phone: family.phone,
            role: family.role,
            createdAt: family.createdAt,
          }),
        );

        const childrenArray = (organization.childrenIds || []).map(
          (child: any) => ({
            id: child._id,
            fullName: child.fullName,
            dateOfBirth: child.dateOfBirth,
            gender: child.gender,
            diagnosis: child.diagnosis,
            parentId: child.parentId,
          }),
        );

        const orgData = {
          id: organization._id,
          name: organization.name,
          staff: staffArray,
          families: familiesArray,
          children: childrenArray,
          totalStaff: staffArray.length,
          totalFamilies: familiesArray.length,
          totalChildren: childrenArray.length,
        };

        console.log(
          'Organization data to return:',
          JSON.stringify(orgData, null, 2),
        );
        userResponse.organization = orgData;
      } else {
        console.log('No organization found for leader:', user._id);
      }
    }

    const response = {
      accessToken,
      refreshToken,
      user: userResponse,
    };

    console.log('Login response user role:', userResponse.role);
    console.log(
      'Login response has organization:',
      !!userResponse.organization,
    );
    if (userResponse.organization) {
      console.log(
        'Organization in response (full):',
        JSON.stringify(userResponse.organization, null, 2),
      );
    }

    console.log('FINAL RESPONSE TO CLIENT:', JSON.stringify(response, null, 2));

    return response;
  }

  async refreshTokens(
    refreshToken: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // Verify refresh token

      const payload = this.jwtService.verify(refreshToken);

      // Find user

      const user = await this.userModel.findById(payload.sub);
      if (!user || !user.refreshToken) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Verify stored refresh token matches
      const refreshTokenMatches = await bcrypt.compare(
        refreshToken,
        user.refreshToken,
      );
      if (!refreshTokenMatches) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Generate new tokens
      const tokens = this.generateTokens(user);

      // Hash and store new refresh token
      const hashedRefreshToken = await this.hashRefreshToken(
        tokens.refreshToken,
      );
      user.refreshToken = hashedRefreshToken;
      await user.save();

      return tokens;
    } catch {
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

  /** Update lastSeenAt so the user appears "online" for presence checks. */
  async updatePresence(userId: string): Promise<void> {
    await this.userModel
      .findByIdAndUpdate(userId, { lastSeenAt: new Date() })
      .exec();
  }

  async getProfile(userId: string): Promise<{
    id: string;
    fullName: string;
    email: string;
    phone?: string;
    role: string;
    profilePic?: string;
    createdAt: Date;
  }> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      id: user._id.toString(),
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profilePic: user.profilePic,
      createdAt: user.createdAt || new Date(),
    };
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<{
    id: string;
    fullName: string;
    email: string;
    phone?: string;
    role: string;
    profilePic?: string;
    createdAt: Date;
  }> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    if (dto.fullName !== undefined) user.fullName = dto.fullName;
    if (dto.phone !== undefined) user.phone = dto.phone;
    if (dto.profilePic !== undefined) user.profilePic = dto.profilePic;
    await user.save();
    return this.getProfile(userId);
  }

  async uploadProfilePicture(
    userId: string,
    file: { buffer: Buffer; mimetype: string },
  ): Promise<{
    id: string;
    fullName: string;
    email: string;
    phone?: string;
    role: string;
    profilePic?: string;
    createdAt: Date;
  }> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    let profilePicUrl: string;
    if (this.cloudinary.isConfigured()) {
      // Chaque utilisateur a sa propre photo : publicId = userId (unique par user)
      profilePicUrl = await this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/profiles',
        publicId: userId, // Unique par utilisateur - chaque user a sa propre photo
      });
    } else {
      const path = await import('path');
      const fs = await import('fs/promises');
      const uploadsDir = path.join(process.cwd(), 'uploads', 'profiles');
      await fs.mkdir(uploadsDir, { recursive: true });
      const ext = file.mimetype === 'image/png' ? 'png' : 'jpg';
      const filename = `${userId}.${ext}`; // Unique par utilisateur
      const filePath = path.join(uploadsDir, filename);
      await fs.writeFile(filePath, file.buffer);
      profilePicUrl = `/uploads/profiles/${filename}`;
    }
    // Sauvegarder l'URL de la photo dans le document user de cet utilisateur spécifique
    user.profilePic = profilePicUrl;
    await user.save();
    return this.getProfile(userId);
  }

  async getFamilyMembers(
    userId: string,
  ): Promise<{ id: string; name: string; imageUrl: string }[]> {
    const list = await this.familyMemberModel
      .find({ userId })
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    return list.map((m: Record<string, unknown>) => ({
      id: (m._id as { toString(): string }).toString(),
      name: (m.name as string) ?? 'Membre',
      imageUrl: typeof m.imageUrl === 'string' ? m.imageUrl : '',
    }));
  }

  async addFamilyMember(
    userId: string,
    name: string,
    file: { buffer: Buffer; mimetype: string },
  ): Promise<{ id: string; name: string; imageUrl: string }> {
    let imageUrl: string;
    if (this.cloudinary.isConfigured()) {
      const publicId = `family_${userId}_${Date.now()}`;
      imageUrl = await this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/family',
        publicId,
      });
    } else {
      const path = await import('path');
      const fs = await import('fs/promises');
      const uploadsDir = path.join(process.cwd(), 'uploads', 'family');
      await fs.mkdir(uploadsDir, { recursive: true });
      const ext = file.mimetype === 'image/png' ? 'png' : 'jpg';
      const filename = `${userId}_${Date.now()}.${ext}`;
      const filePath = path.join(uploadsDir, filename);
      await fs.writeFile(filePath, file.buffer);
      imageUrl = `/uploads/family/${filename}`;
    }
    const doc = await this.familyMemberModel.create({
      userId,
      name,
      imageUrl,
    });
    return {
      id: doc._id.toString(),
      name: doc.name,
      imageUrl: doc.imageUrl,
    };
  }

  async deleteFamilyMember(userId: string, memberId: string): Promise<void> {
    const result = await this.familyMemberModel
      .findOneAndDelete({ _id: memberId, userId })
      .exec();
    if (!result) {
      throw new BadRequestException('Family member not found or access denied');
    }
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

    // Send email with the plain code using new template
    await this.mailService.sendPasswordResetCode(email, code);
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

  async resetPassword(
    email: string,
    code: string,
    newPassword: string,
  ): Promise<void> {
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
    const verification = await this.emailVerificationModel
      .findOne({ email })
      .exec();

    if (!verification) {
      throw new BadRequestException(
        'No verification code found for this email',
      );
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

  async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.userModel.findById(userId).select('+passwordHash');
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(
      currentPassword,
      user.passwordHash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Hash and save new password; invalidate refresh token for security
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.passwordHash = hashedPassword;
    user.refreshToken = undefined;
    await user.save();
  }

  async changeEmail(userId: string, newEmail: string): Promise<void> {
    // Check if email is already in use
    const existingUser = await this.userModel.findOne({ email: newEmail });
    if (existingUser) {
      throw new BadRequestException('Email already in use');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Generate verification code for new email
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedCode = await bcrypt.hash(code, 10);

    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10);

    // Delete any existing verification for this email

    await this.emailVerificationModel.deleteMany({ email: newEmail }).exec();

    // Create new verification record
    const verification = new this.emailVerificationModel({
      email: newEmail,
      code: hashedCode,
      expiresAt,
      verified: false,
    });
    await verification.save();

    // Send verification email to new address

    await this.mailService.sendVerificationCode(newEmail, code);

    // Note: Email is not updated yet. User must verify the code first.
    // You may want to add a separate endpoint to complete email change after verification.
  }

  async activateAccount(token: string, newPassword: string): Promise<void> {
    const user = await this.userModel.findOne({ confirmationToken: token });
    if (!user) {
      throw new BadRequestException('Invalid or expired activation token');
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    user.passwordHash = passwordHash;
    user.isConfirmed = true;
    user.confirmationToken = undefined;
    await user.save();

    console.log(
      `[ACTIVATE] User ${user.email} confirmed. Linking to organization...`,
    );

    // Link user to organization and update invitation status
    // We throw error here if link fails to notify the user/frontend
    try {
      await this.organizationService.acceptInvitation(token);
      console.log(
        `[ACTIVATE] Success: Joined organization for token ${token.substring(0, 10)}...`,
      );
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error(
        `[ACTIVATE] Error linking to organization for token ${token.substring(0, 10)}...:`,
        errorMessage,
      );
      // If invitation is not found but user already has organizationId, it might be already processed
      if (!user.organizationId) {
        throw new BadRequestException(
          `Password set, but failed to join organization: ${errorMessage}`,
        );
      }
    }
  }
}
