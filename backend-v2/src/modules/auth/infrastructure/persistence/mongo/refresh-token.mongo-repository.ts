/**
 * Refresh Token MongoDB Repository - Infrastructure Layer
 */
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as crypto from 'crypto';
import { RefreshTokenMongoSchema, RefreshTokenDocument } from './refresh-token.schema';
import { IRefreshTokenRepository } from '../../../domain/repositories/refresh-token.repository.interface';
import { RefreshTokenEntity } from '../../../domain/entities/refresh-token.entity';
import { RefreshTokenMapper } from '../../mappers/refresh-token.mapper';

@Injectable()
export class RefreshTokenMongoRepository implements IRefreshTokenRepository {
  constructor(
    @InjectModel(RefreshTokenMongoSchema.name)
    private readonly model: Model<RefreshTokenDocument>,
  ) {}

  async findById(id: string): Promise<RefreshTokenEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).exec();
    return doc ? RefreshTokenMapper.toDomain(doc) : null;
  }

  async findByUserId(userId: string): Promise<RefreshTokenEntity[]> {
    const docs = await this.model
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
    return docs.map(RefreshTokenMapper.toDomain);
  }

  async findByTokenHash(tokenHash: string): Promise<RefreshTokenEntity | null> {
    const doc = await this.model.findOne({ tokenHash }).exec();
    return doc ? RefreshTokenMapper.toDomain(doc) : null;
  }

  async findAll(): Promise<RefreshTokenEntity[]> {
    const docs = await this.model.find().exec();
    return docs.map(RefreshTokenMapper.toDomain);
  }

  async save(entity: RefreshTokenEntity): Promise<RefreshTokenEntity> {
    const persistenceData = RefreshTokenMapper.toPersistence(entity);
    const existingDoc = await this.model.findById(entity.id).exec();

    if (existingDoc) {
      const updated = await this.model
        .findByIdAndUpdate(entity.id, persistenceData, { new: true })
        .exec();
      return RefreshTokenMapper.toDomain(updated!);
    } else {
      const newDoc = new this.model({
        _id: new Types.ObjectId(entity.id),
        ...persistenceData,
      });
      const saved = await newDoc.save();
      return RefreshTokenMapper.toDomain(saved);
    }
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.model.deleteOne({ _id: new Types.ObjectId(id) }).exec();
    return result.deletedCount > 0;
  }

  async deleteByUserId(userId: string): Promise<number> {
    const result = await this.model
      .deleteMany({ userId: new Types.ObjectId(userId) })
      .exec();
    return result.deletedCount;
  }

  async deleteExpired(): Promise<number> {
    const result = await this.model.deleteMany({ expiresAt: { $lt: new Date() } }).exec();
    return result.deletedCount;
  }

  async exists(id: string): Promise<boolean> {
    const count = await this.model.countDocuments({ _id: new Types.ObjectId(id) }).exec();
    return count > 0;
  }
}
