import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  IBadgeRepository,
  IChildBadgeRepository,
  IPointsRepository,
  IGameSessionRepository,
} from "../../../domain/repositories/gamification.repository.interface";
import {
  BadgeEntity,
  ChildBadgeEntity,
  PointsEntity,
  GameSessionEntity,
} from "../../../domain/entities/gamification.entity";
import {
  BadgeMapper,
  ChildBadgeMapper,
  PointsMapper,
  GameSessionMapper,
} from "../../mappers/gamification.mapper";

@Injectable()
export class BadgeMongoRepository implements IBadgeRepository {
  constructor(@InjectModel("Badge") private readonly model: Model<any>) {}
  async findAll(activeOnly = true): Promise<BadgeEntity[]> {
    const q = activeOnly ? { isActive: true } : {};
    return (await this.model.find(q).lean().exec()).map(BadgeMapper.toDomain);
  }
  async findByBadgeId(badgeId: string): Promise<BadgeEntity | null> {
    const doc = await this.model.findOne({ badgeId }).lean().exec();
    return doc ? BadgeMapper.toDomain(doc) : null;
  }
  async save(entity: BadgeEntity): Promise<BadgeEntity> {
    const data = BadgeMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return BadgeMapper.toDomain(doc.toObject());
  }
}

@Injectable()
export class ChildBadgeMongoRepository implements IChildBadgeRepository {
  constructor(@InjectModel("ChildBadge") private readonly model: Model<any>) {}
  async findByChildId(childId: string): Promise<ChildBadgeEntity[]> {
    return (
      await this.model
        .find({ childId: new Types.ObjectId(childId) })
        .sort({ earnedAt: -1 })
        .lean()
        .exec()
    ).map(ChildBadgeMapper.toDomain);
  }
  async findOne(
    childId: string,
    badgeIdString: string,
  ): Promise<ChildBadgeEntity | null> {
    const doc = await this.model
      .findOne({ childId: new Types.ObjectId(childId), badgeIdString })
      .lean()
      .exec();
    return doc ? ChildBadgeMapper.toDomain(doc) : null;
  }
  async save(entity: ChildBadgeEntity): Promise<ChildBadgeEntity> {
    const data = ChildBadgeMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return ChildBadgeMapper.toDomain(doc.toObject());
  }
}

@Injectable()
export class PointsMongoRepository implements IPointsRepository {
  constructor(@InjectModel("Points") private readonly model: Model<any>) {}
  async findByChildId(childId: string): Promise<PointsEntity | null> {
    const doc = await this.model
      .findOne({ childId: new Types.ObjectId(childId) })
      .lean()
      .exec();
    return doc ? PointsMapper.toDomain(doc) : null;
  }
  async save(entity: PointsEntity): Promise<PointsEntity> {
    const data = PointsMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return PointsMapper.toDomain(doc.toObject());
  }
  async update(entity: PointsEntity): Promise<PointsEntity> {
    const data = PointsMapper.toPersistence(entity);
    const { _id, ...rest } = data;
    await this.model.updateOne({ _id }, { $set: rest }).exec();
    return entity;
  }
}

@Injectable()
export class GameSessionMongoRepository implements IGameSessionRepository {
  constructor(@InjectModel("GameSession") private readonly model: Model<any>) {}
  async findByChildId(
    childId: string,
    limit = 10,
  ): Promise<GameSessionEntity[]> {
    return (
      await this.model
        .find({ childId: new Types.ObjectId(childId) })
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean()
        .exec()
    ).map(GameSessionMapper.toDomain);
  }
  async save(entity: GameSessionEntity): Promise<GameSessionEntity> {
    const data = GameSessionMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return GameSessionMapper.toDomain(doc.toObject());
  }
}
