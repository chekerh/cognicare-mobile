/**
 * User MongoDB Repository - Infrastructure Layer
 */
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { UserMongoSchema, UserDocument } from './user.schema';
import { IUserRepository } from '../../../domain/repositories/user.repository.interface';
import { UserEntity, UserRole } from '../../../domain/entities/user.entity';
import { UserMapper } from '../../mappers/user.mapper';

@Injectable()
export class UserMongoRepository implements IUserRepository {
  constructor(
    @InjectModel(UserMongoSchema.name)
    private readonly userModel: Model<UserDocument>,
  ) {}

  async findById(id: string): Promise<UserEntity | null> {
    const doc = await this.userModel
      .findOne({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return doc ? UserMapper.toDomain(doc) : null;
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    const doc = await this.userModel
      .findOne({ email: email.toLowerCase(), deletedAt: null })
      .exec();
    return doc ? UserMapper.toDomain(doc) : null;
  }

  async findByRole(role: UserRole): Promise<UserEntity[]> {
    const docs = await this.userModel
      .find({ role, deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(UserMapper.toDomain);
  }

  async findByOrganizationId(organizationId: string): Promise<UserEntity[]> {
    const docs = await this.userModel
      .find({ organizationId: new Types.ObjectId(organizationId), deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(UserMapper.toDomain);
  }

  async findByIds(ids: string[]): Promise<UserEntity[]> {
    const docs = await this.userModel
      .find({ 
        _id: { $in: ids.map(id => new Types.ObjectId(id)) }, 
        deletedAt: null 
      })
      .exec();
    return docs.map(UserMapper.toDomain);
  }

  async findAll(): Promise<UserEntity[]> {
    const docs = await this.userModel
      .find({ deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(UserMapper.toDomain);
  }

  async save(entity: UserEntity): Promise<UserEntity> {
    const persistenceData = UserMapper.toPersistence(entity);
    const existingDoc = await this.userModel.findById(entity.id).exec();

    if (existingDoc) {
      const updated = await this.userModel
        .findByIdAndUpdate(entity.id, persistenceData, { new: true })
        .exec();
      return UserMapper.toDomain(updated!);
    } else {
      const newDoc = new this.userModel({
        _id: new Types.ObjectId(entity.id),
        ...persistenceData,
      });
      const saved = await newDoc.save();
      return UserMapper.toDomain(saved);
    }
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.userModel
      .deleteOne({ _id: new Types.ObjectId(id) })
      .exec();
    return result.deletedCount > 0;
  }

  async exists(id: string): Promise<boolean> {
    const count = await this.userModel
      .countDocuments({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return count > 0;
  }

  async countByRole(role: UserRole): Promise<number> {
    return this.userModel.countDocuments({ role, deletedAt: null }).exec();
  }

  async countByOrganizationId(organizationId: string): Promise<number> {
    return this.userModel
      .countDocuments({ organizationId: new Types.ObjectId(organizationId), deletedAt: null })
      .exec();
  }

  async findWithPagination(
    page: number,
    limit: number,
    filter?: Partial<UserEntity>,
  ): Promise<{ data: UserEntity[]; total: number; page: number; limit: number }> {
    const query: Record<string, unknown> = { deletedAt: null };
    
    if (filter) {
      if (filter.role) query.role = filter.role;
      if (filter.organizationId) query.organizationId = new Types.ObjectId(filter.organizationId);
    }

    const [docs, total] = await Promise.all([
      this.userModel
        .find(query)
        .skip((page - 1) * limit)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.userModel.countDocuments(query).exec(),
    ]);

    return {
      data: docs.map(UserMapper.toDomain),
      total,
      page,
      limit,
    };
  }

  async count(filter?: Partial<UserEntity>): Promise<number> {
    const query: Record<string, unknown> = { deletedAt: null };
    
    if (filter) {
      if (filter.role) query.role = filter.role;
      if (filter.organizationId) query.organizationId = new Types.ObjectId(filter.organizationId);
    }

    return this.userModel.countDocuments(query).exec();
  }
}
