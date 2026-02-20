import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  NutritionPlan,
  NutritionPlanDocument,
} from './schemas/nutrition-plan.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateNutritionPlanDto } from './dto/create-nutrition-plan.dto';
import { UpdateNutritionPlanDto } from './dto/update-nutrition-plan.dto';

@Injectable()
export class NutritionService {
  constructor(
    @InjectModel(NutritionPlan.name)
    private nutritionPlanModel: Model<NutritionPlanDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) { }

  /**
   * Create a nutrition plan for a child
   * Only parent or healthcare professional can create
   */
  async create(dto: CreateNutritionPlanDto, userId: string) {
    // Verify child exists
    const child = await this.childModel.findById(dto.childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    // Verify user is authorized (parent of child or healthcare professional)
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new ForbiddenException('User not found');
    }

    const isParent = child.parentId?.toString() === userId;
    const isHealthcare = [
      'doctor',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
    ].includes(user.role);

    if (!isParent && !isHealthcare) {
      throw new ForbiddenException(
        'Not authorized to create nutrition plan for this child',
      );
    }

    // Create nutrition plan
    const nutritionPlan = new this.nutritionPlanModel({
      ...dto,
      childId: new Types.ObjectId(dto.childId),
      createdBy: new Types.ObjectId(userId),
    });

    await nutritionPlan.save();

    return this.formatNutritionPlan(nutritionPlan);
  }

  /**
   * Get nutrition plan for a child
   */
  async findByChildId(childId: string, userId: string) {
    const child = await this.childModel.findById(childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    // Verify authorization
    await this.verifyAccess(childId, userId);

    const plan = await this.nutritionPlanModel
      .findOne({ childId: new Types.ObjectId(childId), isActive: true })
      .sort({ createdAt: -1 })
      .exec();

    if (!plan) {
      throw new NotFoundException(
        'No active nutrition plan found for this child',
      );
    }

    return this.formatNutritionPlan(plan);
  }

  /**
   * Update nutrition plan
   */
  async update(planId: string, dto: UpdateNutritionPlanDto, userId: string) {
    const plan = await this.nutritionPlanModel.findById(planId);
    if (!plan) {
      throw new NotFoundException('Nutrition plan not found');
    }

    // Verify authorization
    await this.verifyAccess(plan.childId.toString(), userId);

    Object.assign(plan, dto);
    await plan.save();

    return this.formatNutritionPlan(plan);
  }

  /**
   * Delete (deactivate) nutrition plan
   */
  async delete(planId: string, userId: string) {
    const plan = await this.nutritionPlanModel.findById(planId);
    if (!plan) {
      throw new NotFoundException('Nutrition plan not found');
    }

    // Verify authorization
    await this.verifyAccess(plan.childId.toString(), userId);

    plan.isActive = false;
    await plan.save();

    return { message: 'Nutrition plan deactivated successfully' };
  }

  /**
   * Verify user has access to child's nutrition data
   */
  private async verifyAccess(childId: string, userId: string) {
    const child = await this.childModel.findById(childId);
    if (!child) {
      throw new NotFoundException('Child not found');
    }

    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new ForbiddenException('User not found');
    }

    const isParent = child.parentId?.toString() === userId;
    const isHealthcare = [
      'doctor',
      'psychologist',
      'speech_therapist',
      'occupational_therapist',
    ].includes(user.role);

    if (!isParent && !isHealthcare) {
      throw new ForbiddenException(
        'Not authorized to access this nutrition plan',
      );
    }
  }

  /**
   * Format nutrition plan for response
   */
  private formatNutritionPlan(plan: NutritionPlanDocument) {
    return {
      id: plan._id.toString(),
      childId: plan.childId.toString(),
      createdBy: plan.createdBy.toString(),
      dailyWaterGoal: plan.dailyWaterGoal,
      waterReminderInterval: plan.waterReminderInterval,
      breakfast: plan.breakfast || [],
      breakfastTime: plan.breakfastTime,
      lunch: plan.lunch || [],
      lunchTime: plan.lunchTime,
      dinner: plan.dinner || [],
      dinnerTime: plan.dinnerTime,
      snacks: plan.snacks || [],
      allergies: plan.allergies || [],
      restrictions: plan.restrictions || [],
      preferences: plan.preferences || [],
      medications: plan.medications || [],
      specialNotes: plan.specialNotes,
      isActive: plan.isActive,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    };
  }
}
