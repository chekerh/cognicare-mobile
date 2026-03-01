import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { NutritionPlanEntity, TaskReminderEntity, INutritionPlanRepository, ITaskReminderRepository } from '../../domain';
import { NutritionPlanMapper, TaskReminderMapper } from '../mappers/nutrition.mapper';

@Injectable()
export class NutritionPlanMongoRepository implements INutritionPlanRepository {
  constructor(@InjectModel('NutritionPlan') private readonly model: Model<any>) {}

  async findByChildId(childId: string, activeOnly = true): Promise<NutritionPlanEntity | null> {
    const query: any = { childId: new Types.ObjectId(childId) };
    if (activeOnly) query.isActive = true;
    const doc = await this.model.findOne(query).sort({ createdAt: -1 }).lean().exec();
    return doc ? NutritionPlanMapper.toDomain(doc) : null;
  }

  async findById(id: string): Promise<NutritionPlanEntity | null> {
    const doc = await this.model.findById(id).lean().exec();
    return doc ? NutritionPlanMapper.toDomain(doc) : null;
  }

  async save(entity: NutritionPlanEntity): Promise<NutritionPlanEntity> {
    const data = NutritionPlanMapper.toPersistence(entity);
    const doc = await this.model.findByIdAndUpdate(entity.id, { $set: data }, { upsert: true, new: true, lean: true }).exec();
    return NutritionPlanMapper.toDomain(doc);
  }

  async update(entity: NutritionPlanEntity): Promise<NutritionPlanEntity> {
    const data = NutritionPlanMapper.toPersistence(entity);
    const doc = await this.model.findByIdAndUpdate(entity.id, { $set: data }, { new: true, lean: true }).exec();
    if (!doc) throw new Error(`NutritionPlan ${entity.id} not found`);
    return NutritionPlanMapper.toDomain(doc);
  }
}

@Injectable()
export class TaskReminderMongoRepository implements ITaskReminderRepository {
  constructor(@InjectModel('TaskReminder') private readonly model: Model<any>) {}

  async findByChildId(childId: string, activeOnly = true): Promise<TaskReminderEntity[]> {
    const query: any = { childId: new Types.ObjectId(childId) };
    if (activeOnly) query.isActive = true;
    const docs = await this.model.find(query).sort({ createdAt: -1 }).lean().exec();
    return docs.map(TaskReminderMapper.toDomain);
  }

  async findById(id: string): Promise<TaskReminderEntity | null> {
    const doc = await this.model.findById(id).lean().exec();
    return doc ? TaskReminderMapper.toDomain(doc) : null;
  }

  async save(entity: TaskReminderEntity): Promise<TaskReminderEntity> {
    const data = TaskReminderMapper.toPersistence(entity);
    const doc = await this.model.findByIdAndUpdate(entity.id, { $set: data }, { upsert: true, new: true, lean: true }).exec();
    return TaskReminderMapper.toDomain(doc);
  }

  async update(entity: TaskReminderEntity): Promise<TaskReminderEntity> {
    const data = TaskReminderMapper.toPersistence(entity);
    const doc = await this.model.findByIdAndUpdate(entity.id, { $set: data }, { new: true, lean: true }).exec();
    if (!doc) throw new Error(`TaskReminder ${entity.id} not found`);
    return TaskReminderMapper.toDomain(doc);
  }
}
