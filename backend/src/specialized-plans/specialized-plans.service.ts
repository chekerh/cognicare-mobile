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
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as crypto from 'crypto';

@Injectable()
export class SpecializedPlansService {
  constructor(
    @InjectModel(SpecializedPlan.name)
    private planModel: Model<SpecializedPlanDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    private cloudinary: CloudinaryService,
  ) { }

  async uploadImage(file: { buffer: Buffer; mimetype: string }): Promise<string> {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    const m = (file.mimetype ?? '').toLowerCase();
    const mimetype = !m || m === 'application/octet-stream' ? 'image/jpeg' : m;
    if (!allowed.includes(mimetype) && !mimetype.startsWith('image/')) {
      throw new ForbiddenException('Invalid file type. Use JPEG, PNG or WebP.');
    }
    if (this.cloudinary.isConfigured()) {
      const publicId = `pecs-${crypto.randomUUID()}`;
      return this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/pecs',
        publicId,
      });
    }
    const uploadsDir = path.join(process.cwd(), 'uploads', 'pecs');
    await fs.mkdir(uploadsDir, { recursive: true });
    const ext = mimetype === 'image/png' ? 'png' : mimetype === 'image/webp' ? 'webp' : 'jpg';
    const filename = `${crypto.randomUUID()}.${ext}`;
    await fs.writeFile(path.join(uploadsDir, filename), file.buffer);
    return `/uploads/pecs/${filename}`;
  }

  async createPlan(
    specialistId: string,
    organizationId: string | undefined,
    data: {
      childId: string;
      type: 'PECS' | 'TEACCH' | 'SkillTracker' | 'Activity';
      title: string;
      content: any;
    },
  ): Promise<SpecializedPlan> {
    // Verify child exists
    const child = await this.childModel.findById(data.childId);
    if (!child) throw new NotFoundException('Child not found');

    // If org-linked, verify child belongs to same org
    if (organizationId && child.organizationId) {
      if (child.organizationId.toString() !== organizationId) {
        throw new ForbiddenException(
          'Child does not belong to your organization',
        );
      }
    }

    const planData: any = {
      ...data,
      specialistId: new Types.ObjectId(specialistId),
      childId: new Types.ObjectId(data.childId),
    };

    if (organizationId) {
      planData.organizationId = new Types.ObjectId(organizationId);
    }

    const plan = new this.planModel(planData);
    return await plan.save();
  }

  async getPlansByChild(
    childId: string,
    orgId: string | undefined,
  ): Promise<SpecializedPlan[]> {
    const filter: Record<string, unknown> = { childId, status: 'active' };
    if (orgId) {
      filter.organizationId = new Types.ObjectId(orgId);
    } else {
      filter.$or = [
        { organizationId: { $exists: false } },
        { organizationId: null },
      ];
    }
    return this.planModel
      .find(filter)
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
