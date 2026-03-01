import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { IDonationRepository } from '../../../domain/repositories/donation.repository.interface';
import { DonationEntity } from '../../../domain/entities/donation.entity';
import { DonationMapper } from '../../mappers/donation.mapper';

@Injectable()
export class DonationMongoRepository implements IDonationRepository {
  constructor(@InjectModel('Donation') private readonly model: Model<any>) {}

  async findAll(filters?: { isOffer?: boolean; category?: number; search?: string }): Promise<DonationEntity[]> {
    const q: Record<string, unknown> = {};
    if (filters?.isOffer !== undefined) q.isOffer = filters.isOffer;
    if (filters?.category !== undefined && filters.category > 0) {
      const map: Record<number, number> = { 1: 1, 2: 2, 3: 0 };
      const backendCat = map[filters.category];
      if (backendCat !== undefined) q.category = backendCat;
    }
    if (filters?.search?.trim()) {
      const s = filters.search.trim();
      q.$or = [
        { title: new RegExp(s, 'i') },
        { description: new RegExp(s, 'i') },
        { location: new RegExp(s, 'i') },
      ];
    }
    const docs = await this.model.find(q).sort({ createdAt: -1 }).lean().exec();
    return docs.map(DonationMapper.toDomain);
  }

  async findById(id: string): Promise<DonationEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).lean().exec();
    return doc ? DonationMapper.toDomain(doc) : null;
  }

  async save(entity: DonationEntity): Promise<DonationEntity> {
    const data = DonationMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return DonationMapper.toDomain(doc.toObject());
  }
}
