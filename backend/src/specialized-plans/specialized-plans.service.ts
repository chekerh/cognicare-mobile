import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  SpecializedPlan,
  SpecializedPlanDocument,
} from './schemas/specialized-plan.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';

@Injectable()
export class SpecializedPlansService {
  constructor(
    @InjectModel(SpecializedPlan.name)
    private planModel: Model<SpecializedPlanDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
  ) {}

  async createPlan(
    specialistId: string,
    organizationId: string,
    data: {
      childId: string;
      type: 'PECS' | 'TEACCH';
      title: string;
      content: any;
    },
  ): Promise<SpecializedPlan> {
    // Verify child belongs to organization
    const child = await this.childModel.findById(data.childId);
    if (!child) throw new NotFoundException('Child not found');

    if (child.organizationId?.toString() !== organizationId) {
      throw new ForbiddenException(
        'Child does not belong to your organization',
      );
    }

    const plan = new this.planModel({
      ...data,
      specialistId: new Types.ObjectId(specialistId),
      organizationId: new Types.ObjectId(organizationId),
      childId: new Types.ObjectId(data.childId),
    });

    return await plan.save();
  }

  async getPlansByChild(
    childId: string,
    orgId: string,
  ): Promise<SpecializedPlan[]> {
    return this.planModel
      .find({ childId, organizationId: orgId, status: 'active' })
      .sort({ createdAt: -1 });
  }

  async getPlansBySpecialist(specialistId: string): Promise<SpecializedPlan[]> {
    return this.planModel
      .find({ specialistId })
      .populate('childId')
      .sort({ updatedAt: -1 });
  }

  async updatePlan(
    planId: string,
    specialistId: string,
    content: any,
  ): Promise<SpecializedPlan> {
    const plan = await this.planModel.findOne({ _id: planId, specialistId });
    if (!plan) throw new NotFoundException('Plan not found or unauthorized');

    plan.content = content;
    return await plan.save();
  }

  async deletePlan(planId: string, specialistId: string): Promise<void> {
    const result = await this.planModel.deleteOne({
      _id: planId,
      specialistId,
    });
    if (result.deletedCount === 0)
      throw new NotFoundException('Plan not found or unauthorized');
  }
}
