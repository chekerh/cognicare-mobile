/**
 * Child MongoDB Repository - Infrastructure Layer
 * 
 * Concrete implementation of IChildRepository using Mongoose.
 * This is the only place where database operations happen.
 */
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ChildMongoSchema, ChildDocument } from './child.schema';
import { IChildRepository } from '../../../domain/repositories/child.repository.interface';
import { ChildEntity } from '../../../domain/entities/child.entity';
import { ChildMapper } from '../../mappers/child.mapper';

@Injectable()
export class ChildMongoRepository implements IChildRepository {
  constructor(
    @InjectModel(ChildMongoSchema.name)
    private readonly childModel: Model<ChildDocument>,
  ) {}

  async findById(id: string): Promise<ChildEntity | null> {
    const doc = await this.childModel
      .findOne({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return doc ? ChildMapper.toDomain(doc) : null;
  }

  async findByIdIncludingDeleted(id: string): Promise<ChildEntity | null> {
    const doc = await this.childModel
      .findById(new Types.ObjectId(id))
      .exec();
    return doc ? ChildMapper.toDomain(doc) : null;
  }

  async findAll(): Promise<ChildEntity[]> {
    const docs = await this.childModel
      .find({ deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ChildMapper.toDomain);
  }

  async findByParentId(parentId: string): Promise<ChildEntity[]> {
    const docs = await this.childModel
      .find({ 
        parentId: new Types.ObjectId(parentId), 
        deletedAt: null 
      })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ChildMapper.toDomain);
  }

  async findBySpecialistId(specialistId: string): Promise<ChildEntity[]> {
    const docs = await this.childModel
      .find({ 
        specialistId: new Types.ObjectId(specialistId), 
        deletedAt: null 
      })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ChildMapper.toDomain);
  }

  async findByOrganizationId(organizationId: string): Promise<ChildEntity[]> {
    const docs = await this.childModel
      .find({ 
        organizationId: new Types.ObjectId(organizationId), 
        deletedAt: null 
      })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(ChildMapper.toDomain);
  }

  async save(entity: ChildEntity): Promise<ChildEntity> {
    const persistenceData = ChildMapper.toPersistence(entity);

    // Check if this is an update or create
    const existingDoc = await this.childModel.findById(entity.id).exec();

    if (existingDoc) {
      // Update existing document
      const updated = await this.childModel
        .findByIdAndUpdate(entity.id, persistenceData, { new: true })
        .exec();
      return ChildMapper.toDomain(updated!);
    } else {
      // Create new document with specified ID
      const newDoc = new this.childModel({
        _id: new Types.ObjectId(entity.id),
        ...persistenceData,
      });
      const saved = await newDoc.save();
      return ChildMapper.toDomain(saved);
    }
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.childModel
      .deleteOne({ _id: new Types.ObjectId(id) })
      .exec();
    return result.deletedCount > 0;
  }

  async exists(id: string): Promise<boolean> {
    const count = await this.childModel
      .countDocuments({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return count > 0;
  }

  async createMany(children: ChildEntity[]): Promise<ChildEntity[]> {
    const persistenceData = children.map((child) => ({
      _id: new Types.ObjectId(child.id),
      ...ChildMapper.toPersistence(child),
    }));

    const saved = await this.childModel.insertMany(persistenceData);
    return saved.map((doc) => ChildMapper.toDomain(doc as ChildDocument));
  }

  async countByOrganizationId(organizationId: string): Promise<number> {
    return this.childModel
      .countDocuments({ 
        organizationId: new Types.ObjectId(organizationId), 
        deletedAt: null 
      })
      .exec();
  }

  async countBySpecialistId(specialistId: string): Promise<number> {
    return this.childModel
      .countDocuments({ 
        specialistId: new Types.ObjectId(specialistId), 
        deletedAt: null 
      })
      .exec();
  }

  async findWithPagination(
    page: number,
    limit: number,
    filter?: Partial<ChildEntity>,
  ): Promise<{ data: ChildEntity[]; total: number; page: number; limit: number }> {
    const query: Record<string, unknown> = { deletedAt: null };
    
    // Build filter query
    if (filter) {
      if (filter.parentId) query.parentId = new Types.ObjectId(filter.parentId);
      if (filter.organizationId) query.organizationId = new Types.ObjectId(filter.organizationId);
      if (filter.specialistId) query.specialistId = new Types.ObjectId(filter.specialistId);
    }

    const [docs, total] = await Promise.all([
      this.childModel
        .find(query)
        .skip((page - 1) * limit)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.childModel.countDocuments(query).exec(),
    ]);

    return {
      data: docs.map(ChildMapper.toDomain),
      total,
      page,
      limit,
    };
  }

  async count(filter?: Partial<ChildEntity>): Promise<number> {
    const query: Record<string, unknown> = { deletedAt: null };
    
    if (filter) {
      if (filter.parentId) query.parentId = new Types.ObjectId(filter.parentId);
      if (filter.organizationId) query.organizationId = new Types.ObjectId(filter.organizationId);
      if (filter.specialistId) query.specialistId = new Types.ObjectId(filter.specialistId);
    }

    return this.childModel.countDocuments(query).exec();
  }
}
