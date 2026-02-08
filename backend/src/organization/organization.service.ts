import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import {
  Organization,
  OrganizationDocument,
} from './schemas/organization.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import { CreateStaffDto, CreateFamilyDto } from './dto';
import { AddChildDto } from '../children/dto/add-child.dto';
import { UpdateChildDto } from '../children/dto/update-child.dto';

@Injectable()
export class OrganizationService {
  constructor(
    @InjectModel(Organization.name)
    private organizationModel: Model<OrganizationDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
  ) {}

  async createOrganization(
    name: string,
    leaderId: string,
  ): Promise<Organization> {
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

    if (!org.staffIds.some((id) => id.toString() === staff._id.toString())) {
      org.staffIds.push(staff._id as any);
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

    if (!org.familyIds.some((id) => id.toString() === family._id.toString())) {
      org.familyIds.push(family._id as any);
      await org.save();
    }

    // Link family to organization
    family.organizationId = orgId;
    await family.save();

    // Link all family's children to organization
    if (family.childrenIds && family.childrenIds.length > 0) {
      await this.childModel.updateMany(
        { _id: { $in: family.childrenIds } },
        { organizationId: new Types.ObjectId(orgId) },
      );

      // Add children to org's childrenIds
      for (const childId of family.childrenIds) {
        if (
          !org.childrenIds.some((id) => id.toString() === childId.toString())
        ) {
          org.childrenIds.push(childId as any);
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
    if (family && family.childrenIds) {
      org.childrenIds = org.childrenIds.filter(
        (childId) =>
          !family.childrenIds?.some(
            (id) => id.toString() === childId.toString(),
          ),
      );

      // Unlink children from organization
      await this.childModel.updateMany(
        { _id: { $in: family.childrenIds } },
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
    org.staffIds.push(staff._id as any);
    await org.save();
    
    console.log('[CREATE STAFF] Organization updated:', {
      orgId: org._id,
      newStaffCount: org.staffIds.length,
      staffIds: org.staffIds,
    });

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
    org.familyIds.push(family._id as any);

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

        // Add to family's children
        family.childrenIds!.push(child._id as any);

        // Add to organization's children
        org.childrenIds.push(child._id as any);
      }

      await family.save();
    }

    await org.save();

    return { family, children };
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

    // Add to family's children
    family.childrenIds!.push(child._id as any);
    await family.save();

    // Add to organization's children
    org.childrenIds.push(child._id as any);
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
}
