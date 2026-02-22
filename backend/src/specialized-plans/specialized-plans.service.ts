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
    const filter: Record<string, unknown> = {
      childId: new Types.ObjectId(childId),
      status: 'active',
    };
    if (orgId) {
      // Include plans that belong to this org OR have no org (legacy/private plans for this child)
      filter.$or = [
        { organizationId: new Types.ObjectId(orgId) },
        { organizationId: { $exists: false } },
        { organizationId: null },
      ];
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

  /**
   * Get all active plans for a child (for parent progress summary). No org filter.
   */
  async getPlansByChildForParent(childId: string): Promise<SpecializedPlan[]> {
    return this.planModel
      .find({
        childId: new Types.ObjectId(childId),
        status: 'active',
      })
      .sort({ updatedAt: -1 })
      .lean()
      .exec() as Promise<SpecializedPlan[]>;
  }

  /**
   * Compute progress percent 0-100 for a plan (for parent-facing summary).
   */
  static progressPercent(plan: {
    type: string;
    content?: Record<string, unknown>;
  }): number {
    const content = plan.content ?? {};
    if (plan.type === 'PECS') {
      const items = (content.items as Array<{ trials?: unknown[] }>) ?? [];
      let pass = 0,
        total = 0;
      for (const it of items) {
        const trials = it?.trials;
        if (Array.isArray(trials)) {
          for (const t of trials) {
            if (t === true) pass++;
            if (t === true || t === false) total++;
          }
        }
      }
      return total > 0 ? Math.round((pass / total) * 100) : 0;
    }
    if (plan.type === 'TEACCH') {
      const goals = (content.goals as Array<{ current?: number; target?: number }>) ?? [];
      let sumCur = 0,
        sumTarget = 0;
      for (const g of goals) {
        const cur = typeof g?.current === 'number' ? g.current : 0;
        const tgt = typeof g?.target === 'number' ? g.target : 0;
        sumCur += cur;
        sumTarget += tgt;
      }
      if (sumTarget <= 0) return 0;
      return Math.round(Math.min(100, (sumCur / sumTarget) * 100));
    }
    if (plan.type === 'SkillTracker') {
      const cur = typeof content.currentPercent === 'number' ? content.currentPercent : 0;
      const tgt = typeof content.targetPercent === 'number' ? content.targetPercent : 100;
      if (tgt <= 0) return 0;
      return Math.round(Math.min(100, (cur / tgt) * 100));
    }
    if (plan.type === 'Activity') {
      const status = content.status as string | undefined;
      if (status === 'completed') return 100;
      if (status === 'in_progress') return 50;
      return 0;
    }
    return 0;
  }

  /**
   * Parent-facing progress summary: list of plans with progress % and lastUpdated. Verifies child.parentId === parentUserId.
   */
  async getProgressSummaryForParent(
    childId: string,
    parentUserId: string,
  ): Promise<Array<{ planId: string; type: string; title: string; progressPercent: number; lastUpdated?: string }>> {
    const child = await this.childModel.findById(childId).lean().exec();
    if (!child) throw new NotFoundException('Child not found');
    if ((child as any).parentId?.toString() !== parentUserId) {
      throw new ForbiddenException('Not authorized to view this child');
    }
    const plans = await this.getPlansByChildForParent(childId);
    return plans.map((p: any) => ({
      planId: p._id.toString(),
      type: p.type,
      title: p.title,
      progressPercent: SpecializedPlansService.progressPercent({
        type: p.type,
        content: p.content,
      }),
      lastUpdated: p.updatedAt ? new Date(p.updatedAt).toISOString() : undefined,
    }));
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
