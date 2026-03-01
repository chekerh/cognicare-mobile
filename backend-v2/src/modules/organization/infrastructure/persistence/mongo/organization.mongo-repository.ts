/**
 * Organization MongoDB Repository - Infrastructure Layer
 */
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { OrganizationMongoSchema, OrganizationDocument } from './organization.schema';
import { IOrganizationRepository } from '../../../domain/repositories/organization.repository.interface';
import { OrganizationEntity } from '../../../domain/entities/organization.entity';
import { OrganizationMapper } from '../../mappers/organization.mapper';

@Injectable()
export class OrganizationMongoRepository implements IOrganizationRepository {
  constructor(
    @InjectModel(OrganizationMongoSchema.name)
    private readonly orgModel: Model<OrganizationDocument>,
  ) {}

  async findById(id: string): Promise<OrganizationEntity | null> {
    const doc = await this.orgModel
      .findOne({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return doc ? OrganizationMapper.toDomain(doc) : null;
  }

  async findByLeaderId(leaderId: string): Promise<OrganizationEntity | null> {
    const doc = await this.orgModel
      .findOne({ leaderId: new Types.ObjectId(leaderId), deletedAt: null })
      .exec();
    return doc ? OrganizationMapper.toDomain(doc) : null;
  }

  async findByStaffId(staffId: string): Promise<OrganizationEntity | null> {
    const doc = await this.orgModel
      .findOne({ staffIds: new Types.ObjectId(staffId), deletedAt: null })
      .exec();
    return doc ? OrganizationMapper.toDomain(doc) : null;
  }

  async findPending(): Promise<OrganizationEntity[]> {
    const docs = await this.orgModel
      .find({ isApproved: false, rejectedAt: null, deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(OrganizationMapper.toDomain);
  }

  async findApproved(): Promise<OrganizationEntity[]> {
    const docs = await this.orgModel
      .find({ isApproved: true, deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(OrganizationMapper.toDomain);
  }

  async findAll(): Promise<OrganizationEntity[]> {
    const docs = await this.orgModel
      .find({ deletedAt: null })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(OrganizationMapper.toDomain);
  }

  async save(entity: OrganizationEntity): Promise<OrganizationEntity> {
    const persistenceData = OrganizationMapper.toPersistence(entity);
    const existingDoc = await this.orgModel.findById(entity.id).exec();

    if (existingDoc) {
      const updated = await this.orgModel
        .findByIdAndUpdate(entity.id, persistenceData, { new: true })
        .exec();
      return OrganizationMapper.toDomain(updated!);
    } else {
      const newDoc = new this.orgModel({
        _id: new Types.ObjectId(entity.id),
        ...persistenceData,
      });
      const saved = await newDoc.save();
      return OrganizationMapper.toDomain(saved);
    }
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.orgModel
      .deleteOne({ _id: new Types.ObjectId(id) })
      .exec();
    return result.deletedCount > 0;
  }

  async exists(id: string): Promise<boolean> {
    const count = await this.orgModel
      .countDocuments({ _id: new Types.ObjectId(id), deletedAt: null })
      .exec();
    return count > 0;
  }
}
