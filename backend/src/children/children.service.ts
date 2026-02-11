import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Child, ChildDocument } from './schemas/child.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import {
  Organization,
  OrganizationDocument,
} from '../organization/schemas/organization.schema';
import { AddChildDto } from './dto/add-child.dto';

@Injectable()
export class ChildrenService {
  constructor(
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Organization.name)
    private organizationModel: Model<OrganizationDocument>,
  ) {}

  /**
   * Get children for a family. Secured: only the family (parent) or org leader can list.
   */
  async findByFamilyId(familyId: string, requesterId: string) {
    const family = await this.userModel.findById(familyId).lean().exec();
    if (!family) throw new NotFoundException('Family not found');
    if ((family as any).role !== 'family') {
      throw new BadRequestException('User is not a family');
    }
    if ((family as any)._id?.toString() !== requesterId) {
      const org = await this.organizationModel
        .findOne({ leaderId: new Types.ObjectId(requesterId) })
        .lean()
        .exec();
      if (!org) {
        throw new ForbiddenException('Not allowed to list this family children');
      }
      if ((family as any).organizationId?.toString() !== (org as any)._id?.toString()) {
        throw new ForbiddenException('Family not in your organization');
      }
    }
    const children = await this.childModel
      .find({ parentId: new Types.ObjectId(familyId) })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
    return children.map((c) => ({
      id: (c as any)._id.toString(),
      fullName: (c as any).fullName,
      dateOfBirth: (c as any).dateOfBirth,
      gender: (c as any).gender,
      diagnosis: (c as any).diagnosis,
      medicalHistory: (c as any).medicalHistory,
      allergies: (c as any).allergies,
      medications: (c as any).medications,
      notes: (c as any).notes,
      parentId: (c as any).parentId?.toString(),
    }));
  }

  /**
   * Add a child for the current family. Secured: only the family (parent) can add.
   */
  async createForFamily(familyId: string, requesterId: string, dto: AddChildDto) {
    if (requesterId !== familyId) {
      throw new ForbiddenException('You can only add children to your own profile');
    }
    const family = await this.userModel.findById(familyId).exec();
    if (!family) throw new NotFoundException('User not found');
    if (family.role !== 'family') {
      throw new BadRequestException('Only family accounts can add children');
    }

    const child = await this.childModel.create({
      fullName: dto.fullName.trim(),
      dateOfBirth: new Date(dto.dateOfBirth),
      gender: dto.gender,
      diagnosis: dto.diagnosis?.trim(),
      medicalHistory: dto.medicalHistory?.trim(),
      allergies: dto.allergies?.trim(),
      medications: dto.medications?.trim(),
      notes: dto.notes?.trim(),
      parentId: family._id,
      organizationId: family.organizationId,
    });

    if (!family.childrenIds) family.childrenIds = [];
    family.childrenIds.push(child._id as Types.ObjectId);
    await family.save();

    if (family.organizationId) {
      const org = await this.organizationModel.findById(family.organizationId).exec();
      if (org) {
        org.childrenIds = org.childrenIds || [];
        org.childrenIds.push(child._id as Types.ObjectId);
        await org.save();
      }
    }

    return {
      id: child._id.toString(),
      fullName: child.fullName,
      dateOfBirth: child.dateOfBirth,
      gender: child.gender,
      diagnosis: child.diagnosis,
      medicalHistory: child.medicalHistory,
      allergies: child.allergies,
      medications: child.medications,
      notes: child.notes,
      parentId: child.parentId.toString(),
    };
  }
}
