import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Child, ChildDocument } from './schemas/child.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateChildDto } from './dto/create-child.dto';
import { UpdateChildDto } from './dto/update-child.dto';

@Injectable()
export class ChildrenService {
  constructor(
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async create(
    parentId: string,
    createChildDto: CreateChildDto,
  ): Promise<Child> {
    const parent = await this.userModel.findById(parentId);
    if (!parent) throw new NotFoundException('Parent not found');

    const child = new this.childModel({
      ...createChildDto,
      dateOfBirth: new Date(createChildDto.dateOfBirth),
      parentId: new Types.ObjectId(parentId),
      organizationId: parent.organizationId
        ? new Types.ObjectId(parent.organizationId)
        : undefined,
    });

    await child.save();

    // Add child to parent's childrenIds
    if (!parent.childrenIds) {
      parent.childrenIds = [];
    }
    parent.childrenIds.push(child._id as any);
    await parent.save();

    return child;
  }

  async findByParent(parentId: string): Promise<Child[]> {
    return this.childModel
      .find({ parentId: new Types.ObjectId(parentId) })
      .exec();
  }

  async findOne(
    childId: string,
    userId: string,
    userRole: string,
  ): Promise<Child> {
    const child = await this.childModel.findById(childId).exec();
    if (!child) throw new NotFoundException('Child not found');

    // Only parent or organization staff can view
    const parent = await this.userModel.findById(userId);
    const isParent = child.parentId.toString() === userId;
    const isOrgStaff =
      parent?.organizationId &&
      child.organizationId &&
      parent.organizationId === child.organizationId.toString() &&
      [
        'organization_leader',
        'psychologist',
        'speech_therapist',
        'occupational_therapist',
        'doctor',
        'other',
      ].includes(userRole);

    if (!isParent && !isOrgStaff && userRole !== 'admin') {
      throw new ForbiddenException('Access denied');
    }

    return child;
  }

  async update(
    childId: string,
    userId: string,
    updateChildDto: UpdateChildDto,
  ): Promise<Child> {
    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    // Only parent can update
    if (child.parentId.toString() !== userId) {
      throw new ForbiddenException(
        'Only the parent can update child information',
      );
    }

    const updateData: any = { ...updateChildDto };
    if (updateChildDto.dateOfBirth) {
      updateData.dateOfBirth = new Date(updateChildDto.dateOfBirth);
    }

    const updatedChild = await this.childModel.findByIdAndUpdate(
      childId,
      updateData,
      { new: true },
    );

    return updatedChild!;
  }

  async remove(childId: string, userId: string): Promise<void> {
    const child = await this.childModel.findById(childId);
    if (!child) throw new NotFoundException('Child not found');

    // Only parent can delete
    if (child.parentId.toString() !== userId) {
      throw new ForbiddenException('Only the parent can delete child records');
    }

    // Remove from parent's childrenIds
    await this.userModel.findByIdAndUpdate(child.parentId, {
      $pull: { childrenIds: child._id },
    });

    await this.childModel.findByIdAndDelete(childId);
  }
}
