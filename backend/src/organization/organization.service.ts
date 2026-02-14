import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';
import {
  Organization,
  OrganizationDocument,
} from './schemas/organization.schema';
import { Invitation, InvitationDocument } from './schemas/invitation.schema';
import {
  PendingOrganization,
  PendingOrganizationDocument,
} from './schemas/pending-organization.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import {
  CreateStaffDto,
  CreateFamilyDto,
  UpdateStaffDto,
  UpdateFamilyDto,
} from './dto';
import { AddChildDto } from '../children/dto/add-child.dto';
import { UpdateChildDto } from '../children/dto/update-child.dto';
import { MailService } from '../mail/mail.service';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class OrganizationService {
  constructor(
    @InjectModel(Organization.name)
    private organizationModel: Model<OrganizationDocument>,
    @InjectModel(Invitation.name)
    private invitationModel: Model<InvitationDocument>,
    @InjectModel(PendingOrganization.name)
    private pendingOrganizationModel: Model<PendingOrganizationDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    private mailService: MailService,
    private configService: ConfigService,
  ) {}

  async createOrganization(
    name: string,
    leaderId: string,
  ): Promise<OrganizationDocument> {
    const newOrg = new this.organizationModel({
      name,
      leaderId: new Types.ObjectId(leaderId),
      staffIds: [],
      familyIds: [],
      childrenIds: [],
    });
    return newOrg.save();
  }

  async addStaff(orgId: string, staffEmail: string): Promise<User> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const staff = await this.userModel.findOne({ email: staffEmail });
    if (!staff) throw new NotFoundException('User not found');

    // Validate staff role
    const staffRoles = [
      'doctor',
      'volunteer',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ];
    if (!staffRoles.includes(staff.role)) {
      throw new BadRequestException(
        `Cannot add this user as staff. User role is '${staff.role}'. Staff members must have one of these roles: doctor, volunteer, psychologist, speech_therapist, occupational_therapist, or other.`,
      );
    }

    if (!org.staffIds.some((id) => id.toString() === staff._id.toString())) {
      org.staffIds.push(staff._id);
      await org.save();
    }

    // Link staff to organization
    staff.organizationId = orgId;
    await staff.save();

    return staff;
  }

  async removeStaff(orgId: string, staffId: string): Promise<void> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    org.staffIds = org.staffIds.filter((id) => id.toString() !== staffId);
    await org.save();

    // Remove organization link from staff
    await this.userModel.findByIdAndUpdate(staffId, {
      $unset: { organizationId: 1 },
    });
  }

  async getStaff(orgId: string): Promise<User[]> {
    const org = await this.organizationModel
      .findById(orgId)
      .populate('staffIds');
    if (!org) throw new NotFoundException('Organization not found');
    return org.staffIds as any as User[];
  }

  async addFamily(orgId: string, familyEmail: string): Promise<User> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const family = await this.userModel.findOne({ email: familyEmail });
    if (!family) throw new NotFoundException('Family user not found');

    // Validate family role
    if (family.role !== 'family') {
      throw new BadRequestException(
        `Cannot add this user as family. User role is '${family.role}'. Only users with 'family' role can be added as family members.`,
      );
    }

    if (!org.familyIds.some((id) => id.toString() === family._id.toString())) {
      org.familyIds.push(family._id);
      await org.save();
    }

    // Link family to organization
    family.organizationId = orgId;
    await family.save();

    // Link all family's children to organization
    const familyChildren = await this.childModel.find({ parentId: family._id });
    if (familyChildren.length > 0) {
      await this.childModel.updateMany(
        { parentId: family._id },
        { organizationId: new Types.ObjectId(orgId) },
      );

      // Add children to org's childrenIds
      for (const child of familyChildren) {
        if (
          !org.childrenIds.some((id) => id.toString() === child._id.toString())
        ) {
          org.childrenIds.push(child._id);
        }
      }
      await org.save();
    }

    return family;
  }

  async removeFamily(orgId: string, familyId: string): Promise<void> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const family = await this.userModel.findById(familyId);

    // Remove family from organization
    org.familyIds = org.familyIds.filter((id) => id.toString() !== familyId);

    // Remove family's children from organization
    if (family) {
      const familyChildren = await this.childModel.find({
        parentId: family._id,
      });
      const childrenIds = familyChildren.map((child) => child._id.toString());

      org.childrenIds = org.childrenIds.filter(
        (childId) => !childrenIds.includes(childId.toString()),
      );

      // Unlink children from organization
      await this.childModel.updateMany(
        { parentId: family._id },
        { $unset: { organizationId: 1 } },
      );
    }

    await org.save();

    // Remove organization link from family
    await this.userModel.findByIdAndUpdate(familyId, {
      $unset: { organizationId: 1 },
    });
  }

  async getFamilies(orgId: string): Promise<User[]> {
    const org = await this.organizationModel
      .findById(orgId)
      .populate('familyIds');
    if (!org) throw new NotFoundException('Organization not found');
    return org.familyIds as any as User[];
  }

  async getAllChildren(orgId: string): Promise<Child[]> {
    const org = await this.organizationModel
      .findById(orgId)
      .populate('childrenIds');
    if (!org) throw new NotFoundException('Organization not found');
    return org.childrenIds as any as Child[];
  }

  async getOrganizationStats(orgId: string): Promise<{
    totalStaff: number;
    totalFamilies: number;
    totalChildren: number;
    staffByRole: Record<string, number>;
  }> {
    const org = await this.organizationModel
      .findById(orgId)
      .populate('staffIds');
    if (!org) throw new NotFoundException('Organization not found');

    const staff = org.staffIds as any as User[];
    const staffByRole: Record<string, number> = {};

    staff.forEach((member: User) => {
      staffByRole[member.role] = (staffByRole[member.role] || 0) + 1;
    });

    return {
      totalStaff: org.staffIds.length,
      totalFamilies: org.familyIds.length,
      totalChildren: org.childrenIds.length,
      staffByRole,
    };
  }

  async createStaffMember(
    orgId: string,
    createStaffDto: CreateStaffDto,
  ): Promise<User> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    console.log('[CREATE STAFF] Organization found:', {
      orgId: org._id,
      orgName: org.name,
      currentStaffCount: org.staffIds?.length || 0,
    });

    // Check if user already exists
    const existingUser = await this.userModel.findOne({
      email: createStaffDto.email,
    });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(createStaffDto.password, 12);

    // Create staff user
    const staff = new this.userModel({
      fullName: createStaffDto.fullName,
      email: createStaffDto.email,
      phone: createStaffDto.phone,
      passwordHash,
      role: createStaffDto.role,
      organizationId: orgId,
    });

    await staff.save();
    console.log('[CREATE STAFF] Staff user created:', {
      staffId: staff._id,
      email: staff.email,
      role: staff.role,
    });

    // Add to organization
    org.staffIds.push(staff._id);
    await org.save();

    console.log('[CREATE STAFF] Organization updated:', {
      orgId: org._id,
      newStaffCount: org.staffIds.length,
      staffIds: org.staffIds,
    });

    return staff;
  }

  async updateStaff(
    orgId: string,
    staffId: string,
    updateStaffDto: UpdateStaffDto,
  ): Promise<User> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    // Verify staff belongs to organization
    if (!org.staffIds.some((id) => id.toString() === staffId)) {
      throw new BadRequestException(
        'Staff member does not belong to this organization',
      );
    }

    const staff = await this.userModel.findById(staffId);
    if (!staff) throw new NotFoundException('Staff member not found');

    // Check if email is being changed and if it's already taken
    if (updateStaffDto.email && updateStaffDto.email !== staff.email) {
      const existingUser = await this.userModel.findOne({
        email: updateStaffDto.email,
      });
      if (existingUser) {
        throw new ConflictException('Email is already in use');
      }
      staff.email = updateStaffDto.email;
    }

    // Update fields
    if (updateStaffDto.fullName !== undefined) {
      staff.fullName = updateStaffDto.fullName;
    }
    if (updateStaffDto.phone !== undefined) {
      staff.phone = updateStaffDto.phone;
    }
    if (updateStaffDto.role !== undefined) {
      // Validate role is appropriate for staff
      const allowedRoles = [
        'doctor',
        'volunteer',
        'psychologist',
        'speech_therapist',
        'occupational_therapist',
        'other',
      ];
      if (!allowedRoles.includes(updateStaffDto.role)) {
        throw new BadRequestException('Invalid staff role');
      }
      staff.role = updateStaffDto.role as any;
    }

    await staff.save();
    return staff;
  }

  async createFamilyMember(
    orgId: string,
    createFamilyDto: CreateFamilyDto,
  ): Promise<{ family: User; children: Child[] }> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    // Check if user already exists
    const existingUser = await this.userModel.findOne({
      email: createFamilyDto.email,
    });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(createFamilyDto.password, 12);

    // Create family user
    const family = new this.userModel({
      fullName: createFamilyDto.fullName,
      email: createFamilyDto.email,
      phone: createFamilyDto.phone,
      passwordHash,
      role: 'family',
      organizationId: orgId,
      childrenIds: [],
    });

    await family.save();

    // Add to organization
    org.familyIds.push(family._id);

    // Create children if provided
    const children: Child[] = [];
    if (createFamilyDto.children && createFamilyDto.children.length > 0) {
      for (const childDto of createFamilyDto.children) {
        const child = new this.childModel({
          fullName: childDto.fullName,
          dateOfBirth: new Date(childDto.dateOfBirth),
          gender: childDto.gender,
          diagnosis: childDto.diagnosis,
          medicalHistory: childDto.medicalHistory,
          allergies: childDto.allergies,
          medications: childDto.medications,
          notes: childDto.notes,
          parentId: family._id,
          organizationId: new Types.ObjectId(orgId),
        });

        await child.save();
        children.push(child);

        // Add to organization's children
        org.childrenIds.push(child._id);
      }

      await family.save();
    }

    await org.save();

    return { family, children };
  }

  async updateFamily(
    orgId: string,
    familyId: string,
    updateFamilyDto: UpdateFamilyDto,
  ): Promise<User> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    // Verify family belongs to organization
    if (!org.familyIds.some((id) => id.toString() === familyId)) {
      throw new BadRequestException(
        'Family does not belong to this organization',
      );
    }

    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');

    if (family.role !== 'family') {
      throw new BadRequestException('User is not a family member');
    }

    // Check if email is being changed and if it's already taken
    if (updateFamilyDto.email && updateFamilyDto.email !== family.email) {
      const existingUser = await this.userModel.findOne({
        email: updateFamilyDto.email,
      });
      if (existingUser) {
        throw new ConflictException('Email is already in use');
      }
      family.email = updateFamilyDto.email;
    }

    // Update fields
    if (updateFamilyDto.fullName !== undefined) {
      family.fullName = updateFamilyDto.fullName;
    }
    if (updateFamilyDto.phone !== undefined) {
      family.phone = updateFamilyDto.phone;
    }

    await family.save();
    return family;
  }

  async addChildToFamily(
    orgId: string,
    familyId: string,
    addChildDto: AddChildDto,
  ): Promise<Child> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');

    if (family.role !== 'family') {
      throw new BadRequestException('User is not a family member');
    }

    if (family.organizationId?.toString() !== orgId) {
      throw new BadRequestException(
        'Family does not belong to this organization',
      );
    }

    // Create child
    const child = new this.childModel({
      fullName: addChildDto.fullName,
      dateOfBirth: new Date(addChildDto.dateOfBirth),
      gender: addChildDto.gender,
      diagnosis: addChildDto.diagnosis,
      medicalHistory: addChildDto.medicalHistory,
      allergies: addChildDto.allergies,
      medications: addChildDto.medications,
      notes: addChildDto.notes,
      parentId: family._id,
      organizationId: new Types.ObjectId(orgId),
    });

    await child.save();

    // Add to organization's children
    org.childrenIds.push(child._id);
    await org.save();

    return child;
  }

  async updateChild(
    orgId: string,
    familyId: string,
    childId: string,
    updateChildDto: UpdateChildDto,
  ): Promise<Child> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');

    if (family.role !== 'family') {
      throw new BadRequestException('User is not a family member');
    }

    if (family.organizationId?.toString() !== orgId) {
      throw new BadRequestException(
        'Family does not belong to this organization',
      );
    }

    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    if (child.parentId.toString() !== familyId) {
      throw new BadRequestException('Child does not belong to this family');
    }

    // Update child fields
    if (updateChildDto.fullName !== undefined) {
      child.fullName = updateChildDto.fullName;
    }
    if (updateChildDto.dateOfBirth !== undefined) {
      child.dateOfBirth = new Date(updateChildDto.dateOfBirth);
    }
    if (updateChildDto.gender !== undefined) {
      child.gender = updateChildDto.gender;
    }
    if (updateChildDto.diagnosis !== undefined) {
      child.diagnosis = updateChildDto.diagnosis;
    }
    if (updateChildDto.medicalHistory !== undefined) {
      child.medicalHistory = updateChildDto.medicalHistory;
    }
    if (updateChildDto.allergies !== undefined) {
      child.allergies = updateChildDto.allergies;
    }
    if (updateChildDto.medications !== undefined) {
      child.medications = updateChildDto.medications;
    }
    if (updateChildDto.notes !== undefined) {
      child.notes = updateChildDto.notes;
    }

    await child.save();
    return child;
  }

  async deleteChild(
    orgId: string,
    familyId: string,
    childId: string,
  ): Promise<{ message: string }> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');

    if (family.role !== 'family') {
      throw new BadRequestException('User is not a family member');
    }

    if (family.organizationId?.toString() !== orgId) {
      throw new BadRequestException(
        'Family does not belong to this organization',
      );
    }

    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    if (child.parentId.toString() !== familyId) {
      throw new BadRequestException('Child does not belong to this family');
    }

    // Remove from organization's children
    org.childrenIds = org.childrenIds.filter((id) => id.toString() !== childId);
    await org.save();

    // Delete child
    await this.childModel.findByIdAndDelete(childId);

    return { message: 'Child successfully deleted' };
  }

  // Get organization by leader ID
  async getOrganizationByLeader(
    leaderId: string,
  ): Promise<OrganizationDocument | null> {
    return await this.organizationModel.findOne({
      leaderId: new Types.ObjectId(leaderId),
    });
  }

  // Get leader's organization with full details
  async getMyOrganization(leaderId: string): Promise<OrganizationDocument> {
    const org = await this.organizationModel
      .findOne({ leaderId: new Types.ObjectId(leaderId) })
      .populate('staffIds')
      .populate('familyIds')
      .populate('childrenIds');

    if (!org) {
      throw new NotFoundException(
        'No organization found for this leader. Please create an organization first.',
      );
    }

    return org;
  }

  // Get leader's organization staff
  async getMyStaff(leaderId: string): Promise<User[]> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getStaff(org._id.toString());
  }

  // Get leader's organization families
  async getMyFamilies(leaderId: string): Promise<User[]> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getFamilies(org._id.toString());
  }

  // Get leader's organization children
  async getMyChildren(leaderId: string): Promise<Child[]> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getAllChildren(org._id.toString());
  }

  // Get leader's organization stats
  async getMyStats(leaderId: string): Promise<{
    totalStaff: number;
    totalFamilies: number;
    totalChildren: number;
    staffByRole: Record<string, number>;
  }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getOrganizationStats(org._id.toString());
  }

  // Create staff in leader's organization
  async createMyStaffMember(
    leaderId: string,
    createStaffDto: CreateStaffDto,
  ): Promise<User> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.createStaffMember(org._id.toString(), createStaffDto);
  }

  // Create family in leader's organization
  async createMyFamilyMember(
    leaderId: string,
    createFamilyDto: CreateFamilyDto,
  ): Promise<{ family: User; children: Child[] }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.createFamilyMember(org._id.toString(), createFamilyDto);
  }

  // Add child to family in leader's organization
  async addChildToMyFamily(
    leaderId: string,
    familyId: string,
    addChildDto: AddChildDto,
  ): Promise<Child> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.addChildToFamily(org._id.toString(), familyId, addChildDto);
  }

  // Update child in leader's organization
  async updateMyChild(
    leaderId: string,
    familyId: string,
    childId: string,
    updateChildDto: UpdateChildDto,
  ): Promise<Child> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.updateChild(
      org._id.toString(),
      familyId,
      childId,
      updateChildDto,
    );
  }

  // Delete child from leader's organization
  async deleteMyChild(
    leaderId: string,
    familyId: string,
    childId: string,
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.deleteChild(org._id.toString(), familyId, childId);
  }

  // Update staff in leader's organization
  async updateMyStaff(
    leaderId: string,
    staffId: string,
    updateStaffDto: UpdateStaffDto,
  ): Promise<User> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.updateStaff(org._id.toString(), staffId, updateStaffDto);
  }

  // Remove staff from leader's organization
  async removeMyStaff(
    leaderId: string,
    staffId: string,
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    await this.removeStaff(org._id.toString(), staffId);
    return { message: 'Staff member successfully removed' };
  }

  // Update family in leader's organization
  async updateMyFamily(
    leaderId: string,
    familyId: string,
    updateFamilyDto: UpdateFamilyDto,
  ): Promise<User> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.updateFamily(org._id.toString(), familyId, updateFamilyDto);
  }

  // Remove family from leader's organization
  async removeMyFamily(
    leaderId: string,
    familyId: string,
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    await this.removeFamily(org._id.toString(), familyId);
    return { message: 'Family successfully removed' };
  }

  // Invitation system methods
  async inviteUserToOrganization(
    orgId: string,
    userEmail: string,
    invitationType: 'staff' | 'family',
  ): Promise<{ message: string }> {
    console.log('[INVITE] Starting invitation process:', {
      orgId,
      userEmail,
      invitationType,
    });

    const org = await this.organizationModel.findById(orgId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    // Check if user exists
    const user = await this.userModel.findOne({ email: userEmail });
    if (!user) {
      throw new NotFoundException('User with this email does not exist');
    }

    console.log('[INVITE] User found:', {
      userId: user._id,
      email: user.email,
      role: user.role,
    });

    // Validate user role matches invitation type
    const staffRoles = [
      'doctor',
      'volunteer',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ];

    if (invitationType === 'staff' && !staffRoles.includes(user.role)) {
      throw new BadRequestException(
        `Cannot invite this user as staff. User role is '${user.role}'. Staff members must have one of these roles: doctor, volunteer, psychologist, speech_therapist, occupational_therapist, or other.`,
      );
    }

    if (invitationType === 'family' && user.role !== 'family') {
      throw new BadRequestException(
        `Cannot invite this user as family. User role is '${user.role}'. Only users with 'family' role can be invited as family members.`,
      );
    }

    // Check if user is already in the organization
    const isStaff = org.staffIds.some(
      (id) => id.toString() === user._id.toString(),
    );
    const isFamily = org.familyIds.some(
      (id) => id.toString() === user._id.toString(),
    );

    if (isStaff || isFamily) {
      throw new ConflictException(
        'User is already a member of this organization',
      );
    }

    // Check for existing pending invitation
    const existingInvitation = await this.invitationModel.findOne({
      organizationId: orgId,
      userId: user._id,
      status: 'pending',
    });

    if (existingInvitation) {
      throw new ConflictException(
        'A pending invitation already exists for this user',
      );
    }

    // Generate unique token
    const token = crypto.randomBytes(32).toString('hex');

    // Create invitation
    const invitation = new this.invitationModel({
      organizationId: orgId,
      userId: user._id,
      userEmail: userEmail,
      organizationName: org.name,
      invitationType,
      status: 'pending',
      token,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
    });

    await invitation.save();

    console.log('[INVITE] Invitation created:', {
      invitationId: invitation._id,
      token: token.substring(0, 8) + '...',
      expiresAt: invitation.expiresAt,
    });

    // Send email - ensure proper URL formatting
    let baseUrl =
      this.configService.get<string>('BACKEND_URL') || 'http://localhost:3000';

    // Remove trailing slash if present
    baseUrl = baseUrl.replace(/\/$/, '');

    // Build full URLs (global prefix 'api/v1' is already applied by NestJS)
    const acceptUrl = `${baseUrl}/api/v1/organization/invitations/${token}/accept`;
    const rejectUrl = `${baseUrl}/api/v1/organization/invitations/${token}/reject`;

    console.log('[INVITE] Sending email to:', userEmail);

    await this.mailService.sendOrganizationInvitation(
      userEmail,
      org.name,
      invitationType,
      acceptUrl,
      rejectUrl,
    );

    console.log('[INVITE] Email sent successfully');

    return { message: 'Invitation sent successfully' };
  }

  async acceptInvitation(
    token: string,
  ): Promise<{ message: string; organizationName: string }> {
    const invitation = await this.invitationModel.findOne({
      token,
      status: 'pending',
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found or already processed');
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('Invitation has expired');
    }

    // Add user to organization
    const org = await this.organizationModel.findById(
      invitation.organizationId,
    );
    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    const user = await this.userModel.findById(invitation.userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate user role still matches invitation type
    const staffRoles = [
      'doctor',
      'volunteer',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ];

    if (
      invitation.invitationType === 'staff' &&
      !staffRoles.includes(user.role)
    ) {
      throw new BadRequestException(
        `Cannot accept staff invitation. Your current role is '${user.role}', but staff members must have one of these roles: doctor, volunteer, psychologist, speech_therapist, occupational_therapist, or other.`,
      );
    }

    if (invitation.invitationType === 'family' && user.role !== 'family') {
      throw new BadRequestException(
        `Cannot accept family invitation. Your current role is '${user.role}', but only users with 'family' role can be added as family members.`,
      );
    }

    // Add to appropriate list
    if (invitation.invitationType === 'staff') {
      if (!org.staffIds.some((id) => id.toString() === user._id.toString())) {
        org.staffIds.push(user._id);
      }
    } else {
      if (!org.familyIds.some((id) => id.toString() === user._id.toString())) {
        org.familyIds.push(user._id);
      }

      // Link family's children to organization
      const existingChildren = await this.childModel.find({
        parentId: user._id,
      });
      if (existingChildren.length > 0) {
        await this.childModel.updateMany(
          { parentId: user._id },
          { organizationId: invitation.organizationId },
        );

        // Add children to org's childrenIds
        for (const child of existingChildren) {
          if (
            !org.childrenIds.some(
              (id) => id.toString() === child._id.toString(),
            )
          ) {
            org.childrenIds.push(child._id);
          }
        }
      }
    }

    await org.save();

    // Link user to organization
    if (invitation.organizationId) {
      user.organizationId = invitation.organizationId.toString();
    }
    await user.save();

    // Update invitation status
    invitation.status = 'accepted';
    await invitation.save();

    return {
      message: 'Invitation accepted successfully',
      organizationName: org.name,
    };
  }

  async rejectInvitation(token: string): Promise<{ message: string }> {
    const invitation = await this.invitationModel.findOne({
      token,
      status: 'pending',
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found or already processed');
    }

    invitation.status = 'rejected';
    await invitation.save();

    return { message: 'Invitation rejected' };
  }

  async getPendingInvitations(orgId: string): Promise<Invitation[]> {
    return this.invitationModel.find({
      organizationId: orgId,
      status: 'pending',
    });
  }

  async inviteMyUser(
    leaderId: string,
    userEmail: string,
    invitationType: 'staff' | 'family',
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.inviteUserToOrganization(
      org._id.toString(),
      userEmail,
      invitationType,
    );
  }

  async getMyPendingInvitations(leaderId: string): Promise<Invitation[]> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getPendingInvitations(org._id.toString());
  }

  // Pending Organization Methods
  async createPendingOrganization(
    organizationName: string,
    leaderId: string,
    description?: string,
  ): Promise<PendingOrganization> {
    const user = await this.userModel.findById(leaderId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if user already has a pending request
    const existingRequest = await this.pendingOrganizationModel.findOne({
      requestedBy: leaderId,
      status: 'pending',
    });

    if (existingRequest) {
      throw new ConflictException(
        'You already have a pending organization request',
      );
    }

    // Check if user already has an organization
    const existingOrg = await this.organizationModel.findOne({
      leaderId: new Types.ObjectId(leaderId),
    });

    if (existingOrg) {
      throw new ConflictException('You already have an organization');
    }

    // Create pending request
    const pendingOrg = new this.pendingOrganizationModel({
      organizationName,
      requestedBy: leaderId,
      leaderEmail: user.email,
      leaderFullName: user.fullName,
      description,
      status: 'pending',
    });

    await pendingOrg.save();

    // Send confirmation email to leader
    try {
      await this.mailService.sendOrganizationPending(
        user.email,
        organizationName,
        user.fullName,
      );
    } catch (error) {
      console.error('Failed to send pending organization email:', error);
      // Don't throw error - organization request was created successfully
    }

    return pendingOrg;
  }

  async getAllPendingOrganizations(): Promise<PendingOrganization[]> {
    return this.pendingOrganizationModel
      .find({ status: 'pending' })
      .populate('requestedBy', 'fullName email')
      .sort({ createdAt: -1 });
  }

  async reviewOrganization(
    requestId: string,
    adminId: string,
    decision: 'approved' | 'rejected',
    rejectionReason?: string,
  ): Promise<{ message: string; organization?: Organization }> {
    const pendingOrg = await this.pendingOrganizationModel.findById(requestId);

    if (!pendingOrg) {
      throw new NotFoundException('Pending organization request not found');
    }

    if (pendingOrg.status !== 'pending') {
      throw new BadRequestException(
        `This request has already been ${pendingOrg.status}`,
      );
    }

    const user = await this.userModel.findById(pendingOrg.requestedBy);
    if (!user) {
      throw new NotFoundException('Requesting user not found');
    }

    if (decision === 'approved') {
      // Create the organization
      const newOrg = await this.createOrganization(
        pendingOrg.organizationName,
        pendingOrg.requestedBy.toString(),
      );

      // Update user's organizationId
      user.organizationId = newOrg._id.toString();
      await user.save();

      // Update pending request
      pendingOrg.status = 'approved';
      pendingOrg.reviewedBy = new Types.ObjectId(adminId);
      pendingOrg.reviewedAt = new Date();
      pendingOrg.organizationId = newOrg._id;
      await pendingOrg.save();

      // Send approval email
      try {
        await this.mailService.sendOrganizationApproved(
          user.email,
          pendingOrg.organizationName,
          user.fullName,
        );
      } catch (error) {
        console.error('Failed to send organization approved email:', error);
      }

      return {
        message: 'Organization approved and created successfully',
        organization: newOrg,
      };
    } else {
      // Reject the request
      pendingOrg.status = 'rejected';
      pendingOrg.reviewedBy = new Types.ObjectId(adminId);
      pendingOrg.reviewedAt = new Date();
      pendingOrg.rejectionReason = rejectionReason;
      await pendingOrg.save();

      // Send rejection email
      try {
        await this.mailService.sendOrganizationRejected(
          user.email,
          pendingOrg.organizationName,
          user.fullName,
          rejectionReason,
        );
      } catch (error) {
        console.error('Failed to send organization rejected email:', error);
      }

      return {
        message: 'Organization request rejected',
      };
    }
  }

  async getUserPendingOrganization(
    userId: string,
  ): Promise<PendingOrganization | null> {
    return this.pendingOrganizationModel.findOne({
      requestedBy: userId,
      status: 'pending',
    });
  }

  // Admin: Get all organizations
  async getAllOrganizations(): Promise<OrganizationDocument[]> {
    return this.organizationModel
      .find()
      .populate('leaderId', 'fullName email phone')
      .sort({ createdAt: -1 });
  }

  // Admin: Delete organization
  async deleteOrganization(organizationId: string): Promise<void> {
    const organization = await this.organizationModel.findById(organizationId);
    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    // Remove organizationId from all staff members
    if (organization.staffIds && organization.staffIds.length > 0) {
      await this.userModel.updateMany(
        { _id: { $in: organization.staffIds } },
        { $unset: { organizationId: '' } },
      );
    }

    // Remove organizationId from the leader
    if (organization.leaderId) {
      await this.userModel.findByIdAndUpdate(organization.leaderId, {
        $unset: { organizationId: '' },
      });
    }

    // Delete the organization
    await this.organizationModel.findByIdAndDelete(organizationId);
  }

  // Admin: Update organization
  async updateOrganization(
    organizationId: string,
    updateDto: { organizationName?: string },
  ): Promise<OrganizationDocument> {
    const organization = await this.organizationModel.findById(organizationId);
    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    if (updateDto.organizationName) {
      organization.name = updateDto.organizationName;
    }

    await organization.save();
    return organization;
  }

  // Admin: Get pending organization leader invitations
  async getPendingOrgLeaderInvitations(): Promise<InvitationDocument[]> {
    return this.invitationModel
      .find({
        type: 'org_leader_invite',
        status: 'pending',
      })
      .sort({ createdAt: -1 });
  }

  // Admin: Invite organization leader (creates pending invitation with email)
  async inviteOrganizationLeader(
    organizationName: string,
    leaderFullName: string,
    leaderEmail: string,
    leaderPhone: string | undefined,
    leaderPassword: string,
  ): Promise<{ message: string; invitation: InvitationDocument }> {
    // Check if email already exists
    const existingUser = await this.userModel.findOne({ email: leaderEmail });
    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    // Check if there's already a pending invitation for this email
    const existingInvitation = await this.invitationModel.findOne({
      email: leaderEmail,
      type: 'org_leader_invite',
      status: 'pending',
    });
    if (existingInvitation) {
      throw new ConflictException(
        'An invitation is already pending for this email',
      );
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(leaderPassword, 12);

    // Generate invitation token
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days expiry

    // Create invitation record
    const invitation = await this.invitationModel.create({
      email: leaderEmail,
      type: 'org_leader_invite',
      token,
      expiresAt,
      status: 'pending',
      organizationName,
      leaderFullName,
      leaderPhone,
      leaderPassword: hashedPassword,
      createdAt: new Date(),
    });

    // Generate accept/reject URLs
    const baseUrl =
      this.configService.get<string>('BACKEND_URL') || 'http://localhost:3000';
    const acceptUrl = `${baseUrl}/api/v1/organization/admin/invitations/${token}/accept`;
    const rejectUrl = `${baseUrl}/api/v1/organization/admin/invitations/${token}/reject`;

    // Send invitation email
    const emailSent = await this.mailService.sendOrgLeaderInvitation(
      leaderEmail,
      leaderFullName,
      organizationName,
      acceptUrl,
      rejectUrl,
    );

    const message = emailSent
      ? 'Organization leader invitation sent successfully'
      : 'Organization leader invitation created (email failed - check SendGrid configuration). You may need to manually send the invitation link.';

    return {
      message,
      invitation,
    };
  }

  // Handle org leader invitation acceptance
  async acceptOrgLeaderInvitation(
    token: string,
  ): Promise<{ organization: OrganizationDocument; user: UserDocument }> {
    const invitation = await this.invitationModel.findOne({
      token,
      type: 'org_leader_invite',
      status: 'pending',
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found or already processed');
    }

    if (new Date() > invitation.expiresAt) {
      invitation.status = 'expired';
      await invitation.save();
      throw new BadRequestException('Invitation has expired');
    }

    // Create the user
    const user = await this.userModel.create({
      email: invitation.email,
      fullName: invitation.leaderFullName,
      phone: invitation.leaderPhone,
      passwordHash: invitation.leaderPassword, // Already hashed
      role: 'organization_leader',
    });

    // Create the organization
    const organization = await this.organizationModel.create({
      name: invitation.organizationName,
      leaderId: user._id,
      staffIds: [],
      familyIds: [],
      childrenIds: [],
    });

    // Link user to organization
    user.organizationId = organization._id.toString();
    await user.save();

    // Mark invitation as accepted
    invitation.status = 'accepted';
    await invitation.save();

    return { organization, user };
  }

  // Handle org leader invitation rejection
  async rejectOrgLeaderInvitation(token: string): Promise<void> {
    const invitation = await this.invitationModel.findOne({
      token,
      type: 'org_leader_invite',
      status: 'pending',
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found or already processed');
    }

    invitation.status = 'rejected';
    await invitation.save();
  }

  // Cancel org leader invitation (admin)
  async cancelOrgLeaderInvitation(invitationId: string): Promise<void> {
    const invitation = await this.invitationModel.findById(invitationId);

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.type !== 'org_leader_invite') {
      throw new BadRequestException('Invalid invitation type');
    }

    await this.invitationModel.findByIdAndDelete(invitationId);
  }
}
