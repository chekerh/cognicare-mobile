import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Organization,
  OrganizationDocument,
} from './schemas/organization.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

@Injectable()
export class OrganizationService {
  constructor(
    @InjectModel(Organization.name)
    private organizationModel: Model<OrganizationDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async createOrganization(
    name: string,
    leaderId: string,
  ): Promise<Organization> {
    const newOrg = new this.organizationModel({
      name,
      leaderId: new Types.ObjectId(leaderId),
      staffIds: [],
      childIds: [],
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
}
