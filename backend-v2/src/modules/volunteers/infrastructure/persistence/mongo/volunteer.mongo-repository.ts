import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  VolunteerApplicationEntity,
  VolunteerTaskEntity,
  IVolunteerApplicationRepository,
  IVolunteerTaskRepository,
} from "../../../domain";
import {
  VolunteerApplicationMapper,
  VolunteerTaskMapper,
} from "../../mappers/volunteer.mapper";

@Injectable()
export class VolunteerApplicationMongoRepository implements IVolunteerApplicationRepository {
  constructor(
    @InjectModel("VolunteerApplication") private readonly model: Model<any>,
  ) {}

  async findByUserId(
    userId: string,
  ): Promise<VolunteerApplicationEntity | null> {
    const doc = await this.model.findOne({ userId }).lean().exec();
    return doc ? VolunteerApplicationMapper.toDomain(doc) : null;
  }

  async findById(id: string): Promise<VolunteerApplicationEntity | null> {
    const doc = await this.model.findById(id).lean().exec();
    return doc ? VolunteerApplicationMapper.toDomain(doc) : null;
  }

  async findAll(filters?: {
    status?: string;
  }): Promise<VolunteerApplicationEntity[]> {
    const query: any = {};
    if (filters?.status) query.status = filters.status;
    const docs = await this.model
      .find(query)
      .sort({ createdAt: -1 })
      .lean()
      .exec();
    return docs.map(VolunteerApplicationMapper.toDomain);
  }

  async save(
    entity: VolunteerApplicationEntity,
  ): Promise<VolunteerApplicationEntity> {
    const data = VolunteerApplicationMapper.toPersistence(entity);
    const doc = await this.model
      .findByIdAndUpdate(
        entity.id,
        { $set: data },
        { upsert: true, new: true, lean: true },
      )
      .exec();
    return VolunteerApplicationMapper.toDomain(doc);
  }

  async update(
    entity: VolunteerApplicationEntity,
  ): Promise<VolunteerApplicationEntity> {
    const data = VolunteerApplicationMapper.toPersistence(entity);
    const doc = await this.model
      .findByIdAndUpdate(entity.id, { $set: data }, { new: true, lean: true })
      .exec();
    if (!doc) throw new Error(`VolunteerApplication ${entity.id} not found`);
    return VolunteerApplicationMapper.toDomain(doc);
  }
}

@Injectable()
export class VolunteerTaskMongoRepository implements IVolunteerTaskRepository {
  constructor(
    @InjectModel("VolunteerTask") private readonly model: Model<any>,
  ) {}

  async findByVolunteerId(volunteerId: string): Promise<VolunteerTaskEntity[]> {
    const docs = await this.model
      .find({ volunteerId })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
    return docs.map(VolunteerTaskMapper.toDomain);
  }

  async save(entity: VolunteerTaskEntity): Promise<VolunteerTaskEntity> {
    const data = VolunteerTaskMapper.toPersistence(entity);
    const doc = await this.model
      .findByIdAndUpdate(
        entity.id,
        { $set: data },
        { upsert: true, new: true, lean: true },
      )
      .exec();
    return VolunteerTaskMapper.toDomain(doc);
  }
}
