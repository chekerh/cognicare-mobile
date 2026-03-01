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
import {
  SpecializedPlan,
  SpecializedPlanDocument,
} from '../specialized-plans/schemas/specialized-plan.schema';

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
    @InjectModel(SpecializedPlan.name)
    private planModel: Model<SpecializedPlanDocument>,
    private mailService: MailService,
    private configService: ConfigService,
  ) {}

  async createOrganization(
    name: string,
    leaderId: string,
    certificateUrl?: string,
  ): Promise<OrganizationDocument> {
    const newOrg = new this.organizationModel({
      name,
      leaderId: new Types.ObjectId(leaderId),
      staffIds: [],
      familyIds: [],
      childrenIds: [],
      certificateUrl,
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

  async getStaff(orgId: string, page = 1, limit = 50): Promise<User[]> {
    const skip = (page - 1) * limit;
    return this.userModel
      .find({
        organizationId: orgId,
        role: { $ne: 'family' },
        deletedAt: null,
      })
      .sort({ fullName: 1 })
      .skip(skip)
      .limit(limit)
      .exec();
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

  async getFamilies(orgId: string, page = 1, limit = 50): Promise<User[]> {
    const skip = (page - 1) * limit;
    return this.userModel
      .find({
        organizationId: orgId,
        role: 'family',
        deletedAt: null,
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();
  }

  async getAllChildren(orgId: string, page = 1, limit = 50): Promise<Child[]> {
    const skip = (page - 1) * limit;
    return this.childModel
      .find({
        organizationId: new Types.ObjectId(orgId),
        deletedAt: null,
      })
      .populate('parentId', 'fullName email')
      .sort({ fullName: 1 })
      .skip(skip)
      .limit(limit)
      .exec();
  }

  async getOrganizationStats(orgId: string): Promise<{
    totalStaff: number;
    totalFamilies: number;
    totalChildren: number;
    staffByRole: Record<string, number>;
  }> {
    const [totalStaff, totalFamilies, totalChildren, staff] = await Promise.all(
      [
        this.userModel.countDocuments({
          organizationId: orgId,
          role: { $ne: 'family' },
          deletedAt: null,
        }),
        this.userModel.countDocuments({
          organizationId: orgId,
          role: 'family',
          deletedAt: null,
        }),
        this.childModel.countDocuments({
          organizationId: new Types.ObjectId(orgId),
          deletedAt: null,
        }),
        this.userModel
          .find({
            organizationId: orgId,
            role: { $ne: 'family' },
            deletedAt: null,
          })
          .select('role')
          .exec(),
      ],
    );

    const staffByRole: Record<string, number> = {};
    staff.forEach((member) => {
      staffByRole[member.role] = (staffByRole[member.role] || 0) + 1;
    });

    return {
      totalStaff,
      totalFamilies,
      totalChildren,
      staffByRole,
    };
  }

  async createStaffMember(
    orgId: string,
    createStaffDto: CreateStaffDto,
    requesterId?: string,
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
      addedByOrganizationId: orgId,
      lastModifiedBy: requesterId,
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
    requesterId?: string,
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

    if (requesterId) {
      staff.lastModifiedBy = requesterId;
    }

    await staff.save();
    return staff;
  }

  async createFamilyMember(
    orgId: string | null,
    createFamilyDto: CreateFamilyDto,
    requesterId?: string,
  ): Promise<{ family: User; children: Child[] }> {
    const org = orgId ? await this.organizationModel.findById(orgId) : null;
    if (orgId && !org) throw new NotFoundException('Organization not found');

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
      organizationId: orgId || undefined,
      specialistId: !orgId ? requesterId : undefined,
      addedByOrganizationId: orgId || undefined,
      addedBySpecialistId: !orgId ? requesterId : undefined,
      lastModifiedBy: requesterId,
      childrenIds: [],
    });

    await family.save();

    // Add to organization if linked
    if (org) {
      org.familyIds.push(family._id);
    }

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
          organizationId: orgId ? new Types.ObjectId(orgId) : undefined,
          specialistId:
            !orgId && requesterId ? new Types.ObjectId(requesterId) : undefined,
          addedByOrganizationId: orgId ? new Types.ObjectId(orgId) : undefined,
          addedBySpecialistId:
            !orgId && requesterId ? new Types.ObjectId(requesterId) : undefined,
          lastModifiedBy: requesterId
            ? new Types.ObjectId(requesterId)
            : undefined,
        });

        await child.save();
        children.push(child);

        // Add to organization's children if linked
        if (org) {
          org.childrenIds.push(child._id);
        }
      }
    }

    if (org) {
      await org.save();
    }

    return { family, children };
  }

  async updateFamily(
    orgId: string,
    familyId: string,
    updateFamilyDto: UpdateFamilyDto,
    requesterId?: string,
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

    if (child.parentId?.toString() !== familyId) {
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

    if (child.parentId?.toString() !== familyId) {
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

  // Get user's organization children (leader or specialist)
  async getMyChildren(userId: string): Promise<ChildDocument[]> {
    const user = await this.userModel.findById(userId);
    if (!user || !user.organizationId) {
      throw new NotFoundException('User not linked to any organization');
    }

    return this.getAllChildren(user.organizationId.toString()) as any;
  }

  /**
   * Get org children with plan types and needAttention flag for specialist filters.
   * Returns { childId, childName, diagnosis, planTypes, needAttention }[].
   */
  async getMyChildrenWithPlans(userId: string): Promise<
    Array<{
      childId: string;
      childName: string;
      diagnosis?: string;
      planTypes: string[];
      needAttention: boolean;
    }>
  > {
    const children = await this.getMyChildren(userId);
    const orgId = (
      await this.userModel.findById(userId).select('organizationId').lean()
    )?.organizationId;
    if (!children.length) return [];

    const childIds = children.map((c) => (c as any)._id || (c as any).id);
    const filter: Record<string, unknown> = {
      childId: { $in: childIds },
      status: 'active',
    };
    if (orgId) {
      filter.$or = [
        { organizationId: new Types.ObjectId(orgId.toString()) },
        { organizationId: { $exists: false } },
        { organizationId: null },
      ];
    }
    const plans = await this.planModel
      .find(filter)
      .select('childId type content')
      .lean()
      .exec();

    const planTypesByChild = new Map<string, Set<string>>();
    const minProgressByChild = new Map<string, number>();
    for (const c of children) {
      const cid = ((c as any)._id || (c as any).id).toString();
      planTypesByChild.set(cid, new Set());
      minProgressByChild.set(cid, 100);
    }
    for (const p of plans as Array<{
      childId: { toString(): string };
      type: string;
      content?: any;
    }>) {
      const cid = p.childId?.toString?.() ?? p.childId;
      if (!cid) continue;
      const set = planTypesByChild.get(cid);
      if (set) {
        set.add(p.type);
        const percent = this.planProgressPercent(p.type, p.content);
        const current = minProgressByChild.get(cid) ?? 100;
        minProgressByChild.set(cid, Math.min(current, percent));
      }
    }

    return children.map((c) => {
      const cid = ((c as any)._id || (c as any).id).toString();
      const planTypes = Array.from(planTypesByChild.get(cid) ?? []);
      const minP = minProgressByChild.get(cid) ?? 100;
      const needAttention = planTypes.length > 0 && minP < 30;
      return {
        childId: cid,
        childName: (c as any).fullName ?? '',
        diagnosis: (c as any).diagnosis,
        planTypes,
        needAttention,
      };
    });
  }

  private planProgressPercent(type: string, content: any): number {
    const c = content ?? {};
    if (type === 'PECS') {
      const items = c.items ?? [];
      let pass = 0,
        total = 0;
      for (const it of items) {
        const trials = it?.trials ?? [];
        for (const t of trials) {
          if (t === true) pass++;
          if (t === true || t === false) total++;
        }
      }
      return total > 0 ? Math.round((pass / total) * 100) : 0;
    }
    if (type === 'TEACCH') {
      const goals = c.goals ?? [];
      let sumCur = 0,
        sumTarget = 0;
      for (const g of goals) {
        sumCur += typeof g?.current === 'number' ? g.current : 0;
        sumTarget += typeof g?.target === 'number' ? g.target : 0;
      }
      return sumTarget > 0
        ? Math.round(Math.min(100, (sumCur / sumTarget) * 100))
        : 0;
    }
    if (type === 'SkillTracker') {
      const cur = typeof c.currentPercent === 'number' ? c.currentPercent : 0;
      const tgt = typeof c.targetPercent === 'number' ? c.targetPercent : 100;
      return tgt > 0 ? Math.round(Math.min(100, (cur / tgt) * 100)) : 0;
    }
    if (type === 'Activity') {
      const s = c.status;
      if (s === 'completed') return 100;
      if (s === 'in_progress') return 50;
      return 0;
    }
    return 0;
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
    userData?: { fullName: string; phone?: string; role?: string },
  ): Promise<{ message: string }> {
    console.log('[INVITE] Starting invitation process:', {
      orgId,
      userEmail,
      invitationType,
      userData,
    });

    const org = await this.organizationModel.findById(orgId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    // Check if user exists
    let user = await this.userModel.findOne({ email: userEmail });

    // If user doesn't exist and it's a staff invitation, we create an unconfirmed user
    if (!user && invitationType === 'staff') {
      if (!userData || !userData.fullName || !userData.role) {
        throw new BadRequestException(
          'Full name and role are required to invite a new staff member',
        );
      }

      console.log(
        '[INVITE] Creating new unconfirmed user for staff invitation',
      );
      user = new this.userModel({
        fullName: userData.fullName,
        email: userEmail,
        phone: userData.phone,
        role: userData.role,
        passwordHash: 'WILL_BE_SET_ON_CONFIRMATION', // Placeholder
        isConfirmed: false,
        organizationId: orgId,
      });
      await user.save();
    } else if (!user) {
      throw new NotFoundException(
        'User with this email does not exist. Only existing users can be invited as family members currently.',
      );
    }

    console.log('[INVITE] User targeted:', {
      userId: user._id,
      email: user.email,
      role: user.role,
      isConfirmed: user.isConfirmed,
    });

    // Validate user role matches invitation type (if user already exists with a different role)
    const staffRoles = [
      'doctor',
      'volunteer',
      'careProvider',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ];

    if (invitationType === 'staff' && !staffRoles.includes(user.role)) {
      throw new BadRequestException(
        `Cannot invite this user as staff. User role is '${user.role}'. Staff members must have one of these roles: ${staffRoles.join(', ')}.`,
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

    // If a pending invitation already exists, cancel it so we can resend
    const existingInvitation = await this.invitationModel.findOne({
      organizationId: orgId,
      userEmail: userEmail,
      status: 'pending',
    });

    if (existingInvitation) {
      console.log(
        '[INVITE] Cancelling previous pending invitation for',
        userEmail,
      );
      existingInvitation.status = 'cancelled' as any;
      await existingInvitation.save();
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

    // Store token on user as well for activation flow
    user.confirmationToken = token;
    await user.save();

    console.log('[INVITE] Invitation created and token stored on user:', {
      invitationId: invitation._id,
      userId: user._id,
    });

    // Determine URLs based on whether user already has an account
    let activationUrl: string;
    let rejectUrl: string;

    if (user.isConfirmed) {
      // Existing confirmed user: link directly to backend accept/reject endpoints
      // so they don't have to set a password again
      let backendUrl =
        this.configService.get<string>('BACKEND_URL') ||
        this.configService.get<string>('RENDER_EXTERNAL_URL') ||
        'http://localhost:3000';
      backendUrl = backendUrl.replace(/\/$/, '');
      activationUrl = `${backendUrl}/api/v1/organization/invitations/${token}/accept`;
      rejectUrl = `${backendUrl}/api/v1/organization/invitations/${token}/reject`;
      console.log('[INVITE] Existing confirmed user – using direct accept URL');
    } else {
      // New unconfirmed user: link to web dashboard confirm-account page to set password
      let dashboardUrl =
        this.configService.get<string>('DASHBOARD_URL') ||
        this.configService.get<string>('FRONTEND_URL') ||
        'http://localhost:5173';
      dashboardUrl = dashboardUrl.replace(/\/$/, '');
      activationUrl = `${dashboardUrl}/confirm-account?token=${token}`;
      rejectUrl = `${dashboardUrl}/reject-invitation?token=${token}`;
      console.log('[INVITE] New unconfirmed user – using confirm-account URL');
    }

    console.log('[INVITE] Sending email to:', userEmail);

    await this.mailService.sendOrganizationInvitation(
      userEmail,
      org.name,
      invitationType,
      activationUrl,
      rejectUrl,
    );

    console.log('[INVITE] Email sent successfully');

    return { message: 'Invitation sent successfully' };
  }

  async acceptInvitation(
    token: string,
  ): Promise<{ message: string; organizationName: string }> {
    console.log(
      `[ACCEPT] Processing invitation with token: ${token.substring(0, 10)}...`,
    );

    const invitation = await this.invitationModel.findOne({
      token,
    });

    if (!invitation) {
      console.error('[ACCEPT] Invitation not found for token');
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      console.log(
        `[ACCEPT] Invitation already processed: ${invitation.status}`,
      );
      // If it's already accepted, we can just return success to avoid blocking activation flow
      if (invitation.status === 'accepted') {
        const org = await this.organizationModel.findById(
          invitation.organizationId,
        );
        return {
          message: 'Invitation already accepted',
          organizationName: org?.name || 'Organization',
        };
      }
      throw new BadRequestException(
        `Invitation is already ${invitation.status}`,
      );
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('Invitation has expired');
    }

    const orgId = invitation.organizationId;
    const userId = invitation.userId;

    if (!orgId || !userId) {
      throw new BadRequestException(
        'Invalid invitation data: Missing organization or user ID',
      );
    }

    const org = await this.organizationModel.findById(orgId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Determine invitation type from either field
    const effectiveType = invitation.invitationType || (invitation as any).type;

    console.log(
      `[ACCEPT] Invitation found. Type: ${effectiveType}, User: ${user.email}, Org: ${org.name}`,
    );

    // Validate user role still matches invitation type
    const staffRoles = [
      'doctor',
      'volunteer',
      'careProvider',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
      'other',
    ];

    if (effectiveType === 'staff') {
      if (!staffRoles.includes(user.role)) {
        throw new BadRequestException(
          `Cannot accept staff invitation. Your current role is '${user.role}', but staff members must have a professional role.`,
        );
      }
    } else if (effectiveType === 'family') {
      if (user.role !== 'family') {
        throw new BadRequestException(
          `Cannot accept family invitation. Your current role is '${user.role}', but you must have a 'family' role.`,
        );
      }
    }

    // Add to appropriate list
    if (effectiveType === 'staff') {
      if (!org.staffIds.some((id) => id.toString() === user._id.toString())) {
        org.staffIds.push(user._id);
        console.log(`[ACCEPT] Added user ${user._id.toString()} to staffIds`);
      }
    } else {
      if (!org.familyIds.some((id) => id.toString() === user._id.toString())) {
        org.familyIds.push(user._id);
        console.log(`[ACCEPT] Added user ${user._id.toString()} to familyIds`);
      }

      // Link family's children to organization
      const existingChildren = await this.childModel.find({
        parentId: user._id,
      });
      if (existingChildren.length > 0) {
        await this.childModel.updateMany(
          { parentId: user._id },
          { organizationId: orgId },
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
        console.log(
          `[ACCEPT] Linked ${existingChildren.length} children to organization`,
        );
      }
    }

    await org.save();

    // Link user to organization
    user.organizationId = orgId.toString();
    await user.save();

    console.log(
      `[ACCEPT] User ${user.email} successfully linked to organization ${org.name}`,
    );

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
    userData?: { fullName: string; phone?: string; role?: string },
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.inviteUserToOrganization(
      org._id.toString(),
      userEmail,
      invitationType,
      userData,
    );
  }

  async getMyPendingInvitations(leaderId: string): Promise<Invitation[]> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }
    return this.getPendingInvitations(org._id.toString());
  }

  async cancelInvitation(
    invitationId: string,
    leaderId: string,
  ): Promise<{ message: string }> {
    const org = await this.getOrganizationByLeader(leaderId);
    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    const invitation = await this.invitationModel.findOne({
      _id: invitationId,
      organizationId: org._id,
      status: 'pending',
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found or not pending');
    }

    // If it's a staff invitation, we might also want to delete the user
    // if they were newly created (unconfirmed) and not yet linked to anything else
    const user = await this.userModel.findById(invitation.userId);
    if (user && !user.isConfirmed) {
      console.log(
        '[CANCEL] Deleting unconfirmed user associated with invitation',
      );
      await this.userModel.findByIdAndDelete(user._id);
    }

    // Mark as cancelled
    invitation.status = 'cancelled' as any;
    await invitation.save();

    return { message: 'Invitation cancelled successfully' };
  }

  // Pending Organization Methods
  async createPendingOrganization(
    organizationName: string,
    leaderId: string,
    description?: string,
    certificateUrl?: string,
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
      certificateUrl,
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

  async getReviewedOrganizations(): Promise<PendingOrganization[]> {
    return this.pendingOrganizationModel
      .find({ status: { $in: ['approved', 'rejected'] } })
      .populate('requestedBy', 'fullName email')
      .populate('reviewedBy', 'fullName email')
      .sort({ reviewedAt: -1 });
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
      // Create the organization with certificate URL from pending request
      const newOrg = await this.createOrganization(
        pendingOrg.organizationName,
        pendingOrg.requestedBy.toString(),
        pendingOrg.certificateUrl,
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

  async reReviewOrganization(
    requestId: string,
    adminId: string,
    decision: 'approved' | 'rejected',
    rejectionReason?: string,
  ): Promise<{ message: string; organization?: Organization }> {
    const pendingOrg = await this.pendingOrganizationModel.findById(requestId);

    if (!pendingOrg) {
      throw new NotFoundException('Organization request not found');
    }

    if (pendingOrg.status === 'pending') {
      throw new BadRequestException(
        'Use the regular review endpoint for pending requests',
      );
    }

    const user = await this.userModel.findOne({
      email: pendingOrg.leaderEmail,
    });

    // If changing from rejected to approved
    if (pendingOrg.status === 'rejected' && decision === 'approved') {
      // Check if user still exists, if not create new one
      const targetUser = user;
      if (!targetUser) {
        // User was deleted, need to recreate (admin should handle this separately)
        throw new BadRequestException(
          'User account was deleted. Please create a new organization invitation for this user.',
        );
      }

      // Check if organization already exists
      const existingOrg = await this.organizationModel.findOne({
        leaderId: targetUser._id,
      });

      if (existingOrg) {
        throw new BadRequestException(
          'User already has an approved organization',
        );
      }

      // Create the organization
      const newOrg = await this.createOrganization(
        pendingOrg.organizationName,
        targetUser._id.toString(),
        pendingOrg.certificateUrl,
      );

      // Update user's organizationId
      targetUser.organizationId = newOrg._id.toString();
      await targetUser.save();

      // Update pending request
      pendingOrg.status = 'approved';
      pendingOrg.reviewedBy = new Types.ObjectId(adminId);
      pendingOrg.reviewedAt = new Date();
      pendingOrg.organizationId = newOrg._id;
      pendingOrg.rejectionReason = undefined;
      await pendingOrg.save();

      // Send approval email
      try {
        await this.mailService.sendOrganizationApproved(
          targetUser.email,
          pendingOrg.organizationName,
          targetUser.fullName,
        );
      } catch (error) {
        console.error('Failed to send organization approved email:', error);
      }

      return {
        message: 'Organization approved successfully after re-review',
        organization: newOrg,
      };
    }

    // If changing from approved to rejected
    if (pendingOrg.status === 'approved' && decision === 'rejected') {
      // Find and delete the organization
      if (pendingOrg.organizationId) {
        const org = await this.organizationModel.findById(
          pendingOrg.organizationId,
        );
        if (org) {
          // Remove organizationId from all users
          await this.userModel.updateMany(
            { organizationId: org._id.toString() },
            { $unset: { organizationId: '' } },
          );

          // Delete organization
          await this.organizationModel.findByIdAndDelete(org._id);
        }
      }

      // Update pending request
      pendingOrg.status = 'rejected';
      pendingOrg.reviewedBy = new Types.ObjectId(adminId);
      pendingOrg.reviewedAt = new Date();
      pendingOrg.rejectionReason = rejectionReason;
      pendingOrg.organizationId = undefined;
      await pendingOrg.save();

      // Send rejection email if user exists
      if (user) {
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
      }

      return {
        message: 'Organization rejected successfully after re-review',
      };
    }

    throw new BadRequestException(
      'Invalid re-review decision or status combination',
    );
  }

  async getUserPendingOrganization(
    userId: string,
  ): Promise<PendingOrganization | null> {
    return this.pendingOrganizationModel.findOne({
      requestedBy: userId,
      status: 'pending',
    });
  }

  async getPendingOrganizationById(
    pendingOrgId: string,
  ): Promise<PendingOrganizationDocument | null> {
    return this.pendingOrganizationModel.findById(pendingOrgId);
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

  // Admin: Change organization leader
  async changeOrganizationLeader(
    orgId: string,
    newLeaderEmail: string,
  ): Promise<OrganizationDocument> {
    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    const newLeader = await this.userModel.findOne({ email: newLeaderEmail });
    if (!newLeader) {
      throw new NotFoundException('User with this email not found');
    }

    if (org.leaderId && org.leaderId.toString() === newLeader._id.toString()) {
      throw new BadRequestException('This user is already the leader');
    }

    // Unlink old leader from org
    if (org.leaderId) {
      await this.userModel.findByIdAndUpdate(org.leaderId, {
        $unset: { organizationId: '' },
      });
    }

    // Link new leader to org
    await this.userModel.findByIdAndUpdate(newLeader._id, {
      organizationId: orgId,
      role: 'organization_leader',
    });

    org.leaderId = newLeader._id as any;
    await org.save();

    return (await this.organizationModel
      .findById(orgId)
      .populate('leaderId', 'fullName email')) as OrganizationDocument;
  }

  // Admin: Get all families
  async adminGetAllFamilies(): Promise<unknown[]> {
    return await this.userModel.aggregate([
      { $match: { role: 'family' } },
      {
        $lookup: {
          from: 'children',
          localField: '_id',
          foreignField: 'parentId',
          as: '_children',
        },
      },
      {
        $lookup: {
          from: 'organizations',
          localField: 'organizationId',
          foreignField: '_id',
          as: '_org',
        },
      },
      {
        $addFields: {
          childCount: { $size: '$_children' },
          organizationId: { $arrayElemAt: ['$_org', 0] },
        },
      },
      {
        $project: {
          _children: 0,
          _org: 0,
          passwordHash: 0,
          refreshToken: 0,
        },
      },
      { $sort: { createdAt: -1 } },
    ]);
  }

  // Admin: Get children for a specific family
  async adminGetFamilyChildren(familyId: string): Promise<Child[]> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');
    return await this.childModel.find({
      parentId: new Types.ObjectId(familyId),
    });
  }

  // Admin: Create a new family member
  async adminCreateFamily(dto: {
    fullName: string;
    email: string;
    password: string;
    phone?: string;
    organizationId?: string;
  }): Promise<User> {
    const existing = await this.userModel.findOne({ email: dto.email });
    if (existing) throw new ConflictException('Email already exists');

    const hashedPassword = await bcrypt.hash(dto.password, 12);

    const family = await this.userModel.create({
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      passwordHash: hashedPassword,
      role: 'family',
      organizationId: dto.organizationId || undefined,
    });

    if (dto.organizationId) {
      await this.organizationModel.findByIdAndUpdate(dto.organizationId, {
        $addToSet: { familyIds: family._id },
      });
    }

    return family;
  }

  // Admin: Update a family member
  async adminUpdateFamily(
    familyId: string,
    updateDto: { fullName?: string; email?: string; phone?: string },
  ): Promise<User> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');

    if (updateDto.fullName) family.fullName = updateDto.fullName;
    if (updateDto.email) family.email = updateDto.email;
    if (updateDto.phone !== undefined) family.phone = updateDto.phone;

    await family.save();
    return family;
  }

  // Admin: Delete a family member and all their children
  async adminDeleteFamily(familyId: string): Promise<{ message: string }> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');

    // Delete all children belonging to this family
    const children = await this.childModel.find({
      parentId: new Types.ObjectId(familyId),
    });
    const childIds = children.map((c) => c._id);
    await this.childModel.deleteMany({
      parentId: new Types.ObjectId(familyId),
    });

    // Unlink from organization
    if (family.organizationId) {
      await this.organizationModel.findByIdAndUpdate(family.organizationId, {
        $pull: {
          familyIds: family._id,
          childrenIds: { $in: childIds },
        },
      });
    }

    await this.userModel.findByIdAndDelete(familyId);
    return {
      message: 'Family and all associated children deleted successfully',
    };
  }

  // Admin: Assign a family to an organization
  async adminAssignFamilyToOrg(
    familyId: string,
    orgId: string,
  ): Promise<{ message: string }> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');

    const org = await this.organizationModel.findById(orgId);
    if (!org) throw new NotFoundException('Organization not found');

    // Remove from previous org if any
    if (family.organizationId) {
      const prevOrgId = family.organizationId.toString();
      const prevChildren = await this.childModel.find({
        parentId: family._id,
      });
      const prevChildIds = prevChildren.map((c) => c._id);

      await this.organizationModel.findByIdAndUpdate(prevOrgId, {
        $pull: { familyIds: family._id },
      });
      await this.organizationModel.findByIdAndUpdate(prevOrgId, {
        $pull: { childrenIds: { $in: prevChildIds } },
      });
      await this.childModel.updateMany(
        { parentId: family._id },
        { $unset: { organizationId: '' } },
      );
    }

    // Link family to new org
    family.organizationId = orgId;
    await family.save();

    if (!org.familyIds.some((id) => id.toString() === family._id.toString())) {
      org.familyIds.push(family._id);
    }

    // Link children
    const children = await this.childModel.find({ parentId: family._id });
    if (children.length > 0) {
      await this.childModel.updateMany(
        { parentId: family._id },
        { organizationId: new Types.ObjectId(orgId) },
      );
      for (const child of children) {
        if (
          !org.childrenIds.some((id) => id.toString() === child._id.toString())
        ) {
          org.childrenIds.push(child._id);
        }
      }
    }

    await org.save();
    return { message: 'Family assigned to organization successfully' };
  }

  // Admin: Remove a family from its current organization
  async adminRemoveFamilyFromOrg(
    familyId: string,
  ): Promise<{ message: string }> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');
    if (!family.organizationId) {
      throw new BadRequestException(
        'Family is not assigned to any organization',
      );
    }

    const orgId = family.organizationId.toString();
    await this.removeFamily(orgId, familyId);
    return { message: 'Family removed from organization successfully' };
  }

  // Admin: Add a child to a family
  async adminAddChildToFamily(
    familyId: string,
    addChildDto: AddChildDto,
  ): Promise<Child> {
    const family = await this.userModel.findById(familyId);
    if (!family) throw new NotFoundException('Family not found');
    if (family.role !== 'family')
      throw new BadRequestException('User is not a family member');

    const child = await this.childModel.create({
      fullName: addChildDto.fullName,
      dateOfBirth: new Date(addChildDto.dateOfBirth),
      gender: addChildDto.gender,
      diagnosis: addChildDto.diagnosis,
      medicalHistory: addChildDto.medicalHistory,
      allergies: addChildDto.allergies,
      medications: addChildDto.medications,
      notes: addChildDto.notes,
      parentId: new Types.ObjectId(familyId),
      organizationId: family.organizationId
        ? new Types.ObjectId(family.organizationId.toString())
        : undefined,
    });

    // Link child to family
    await this.userModel.findByIdAndUpdate(familyId, {
      $addToSet: { childrenIds: child._id },
    });

    // Link child to organization
    if (family.organizationId) {
      await this.organizationModel.findByIdAndUpdate(family.organizationId, {
        $addToSet: { childrenIds: child._id },
      });
    }

    return child;
  }

  // Admin: Update a child
  async adminUpdateChild(
    childId: string,
    updateChildDto: UpdateChildDto,
  ): Promise<Child> {
    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    if (updateChildDto.fullName) child.fullName = updateChildDto.fullName;
    if (updateChildDto.dateOfBirth)
      child.dateOfBirth = new Date(updateChildDto.dateOfBirth);
    if (updateChildDto.gender) child.gender = updateChildDto.gender;
    if (updateChildDto.diagnosis !== undefined)
      child.diagnosis = updateChildDto.diagnosis;
    if (updateChildDto.medicalHistory !== undefined)
      child.medicalHistory = updateChildDto.medicalHistory;
    if (updateChildDto.allergies !== undefined)
      child.allergies = updateChildDto.allergies;
    if (updateChildDto.medications !== undefined)
      child.medications = updateChildDto.medications;
    if (updateChildDto.notes !== undefined) child.notes = updateChildDto.notes;

    await child.save();
    return child;
  }

  // Admin: Delete a child
  async adminDeleteChild(
    familyId: string,
    childId: string,
  ): Promise<{ message: string }> {
    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    // Remove from family's childrenIds
    await this.userModel.findByIdAndUpdate(familyId, {
      $pull: { childrenIds: new Types.ObjectId(childId) },
    });

    // Remove from organization's childrenIds
    if (child.organizationId) {
      await this.organizationModel.findByIdAndUpdate(child.organizationId, {
        $pull: { childrenIds: new Types.ObjectId(childId) },
      });
    }

    await this.childModel.findByIdAndDelete(childId);
    return { message: 'Child deleted successfully' };
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
