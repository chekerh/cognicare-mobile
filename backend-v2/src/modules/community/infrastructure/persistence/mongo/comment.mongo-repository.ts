import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { ICommentRepository } from "../../../domain/repositories/comment.repository.interface";
import { CommentEntity } from "../../../domain/entities/comment.entity";
import { CommentMongoSchema, CommentDocument } from "./comment.schema";
import { CommentMapper } from "../../mappers/comment.mapper";

@Injectable()
export class CommentMongoRepository implements ICommentRepository {
  constructor(
    @InjectModel(CommentMongoSchema.name)
    private readonly model: Model<CommentDocument>,
  ) {}

  async findByPostId(postId: string): Promise<CommentEntity[]> {
    const docs = await this.model
      .find({ postId: new Types.ObjectId(postId) })
      .sort({ createdAt: 1 })
      .exec();
    return docs.map(CommentMapper.toDomain);
  }

  async save(entity: CommentEntity): Promise<CommentEntity> {
    const data = CommentMapper.toPersistence(entity);
    const doc = new this.model({ _id: new Types.ObjectId(entity.id), ...data });
    const saved = await doc.save();
    return CommentMapper.toDomain(saved);
  }

  async deleteByPostId(postId: string): Promise<void> {
    await this.model.deleteMany({ postId: new Types.ObjectId(postId) }).exec();
  }
}
