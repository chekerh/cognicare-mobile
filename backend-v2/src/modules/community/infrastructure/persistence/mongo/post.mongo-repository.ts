import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { IPostRepository } from '../../../domain/repositories/post.repository.interface';
import { PostEntity } from '../../../domain/entities/post.entity';
import { PostMongoSchema, PostDocument } from './post.schema';
import { PostMapper } from '../../mappers/post.mapper';

@Injectable()
export class PostMongoRepository implements IPostRepository {
  constructor(
    @InjectModel(PostMongoSchema.name) private readonly model: Model<PostDocument>,
  ) {}

  async findById(id: string): Promise<PostEntity | null> {
    const doc = await this.model.findById(id).exec();
    return doc ? PostMapper.toDomain(doc) : null;
  }

  async findAll(): Promise<PostEntity[]> {
    const docs = await this.model.find().sort({ createdAt: -1 }).exec();
    return docs.map(PostMapper.toDomain);
  }

  async findByAuthorId(authorId: string): Promise<PostEntity[]> {
    const docs = await this.model.find({ authorId: new Types.ObjectId(authorId) }).sort({ createdAt: -1 }).exec();
    return docs.map(PostMapper.toDomain);
  }

  async save(entity: PostEntity): Promise<PostEntity> {
    const data = PostMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return PostMapper.toDomain(saved);
  }

  async update(entity: PostEntity): Promise<void> {
    const data = PostMapper.toPersistence(entity);
    await this.model.findByIdAndUpdate(entity.id, { $set: data }).exec();
  }

  async delete(id: string): Promise<void> {
    await this.model.findByIdAndDelete(id).exec();
  }

  async findByIds(ids: string[]): Promise<PostEntity[]> {
    const docs = await this.model.find({ _id: { $in: ids.map((id) => new Types.ObjectId(id)) } }).exec();
    return docs.map(PostMapper.toDomain);
  }
}
