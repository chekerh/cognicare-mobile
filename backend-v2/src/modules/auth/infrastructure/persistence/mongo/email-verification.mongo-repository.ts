/**
 * Email Verification MongoDB Repository - Infrastructure Layer
 */
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EmailVerificationMongoSchema, EmailVerificationDocument } from './email-verification.schema';
import { IEmailVerificationRepository } from '../../../domain/repositories/email-verification.repository.interface';
import { EmailVerificationEntity } from '../../../domain/entities/email-verification.entity';
import { EmailVerificationMapper } from '../../mappers/email-verification.mapper';

@Injectable()
export class EmailVerificationMongoRepository implements IEmailVerificationRepository {
  constructor(
    @InjectModel(EmailVerificationMongoSchema.name)
    private readonly model: Model<EmailVerificationDocument>,
  ) {}

  async findById(id: string): Promise<EmailVerificationEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).exec();
    return doc ? EmailVerificationMapper.toDomain(doc) : null;
  }

  async findByEmail(email: string): Promise<EmailVerificationEntity | null> {
    const doc = await this.model
      .findOne({ email: email.toLowerCase() })
      .sort({ createdAt: -1 })
      .exec();
    return doc ? EmailVerificationMapper.toDomain(doc) : null;
  }

  async findAll(): Promise<EmailVerificationEntity[]> {
    const docs = await this.model.find().exec();
    return docs.map(EmailVerificationMapper.toDomain);
  }

  async save(entity: EmailVerificationEntity): Promise<EmailVerificationEntity> {
    const persistenceData = EmailVerificationMapper.toPersistence(entity);
    
    // Delete any existing verification for this email first
    await this.model.deleteMany({ email: entity.email }).exec();
    
    const newDoc = new this.model({
      _id: new Types.ObjectId(entity.id),
      ...persistenceData,
    });
    const saved = await newDoc.save();
    return EmailVerificationMapper.toDomain(saved);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.model.deleteOne({ _id: new Types.ObjectId(id) }).exec();
    return result.deletedCount > 0;
  }

  async deleteByEmail(email: string): Promise<boolean> {
    const result = await this.model.deleteMany({ email: email.toLowerCase() }).exec();
    return result.deletedCount > 0;
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
