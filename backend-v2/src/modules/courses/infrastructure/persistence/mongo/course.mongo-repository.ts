import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  ICourseRepository,
  ICourseEnrollmentRepository,
} from "../../../domain/repositories/course.repository.interface";
import {
  CourseEntity,
  CourseEnrollmentEntity,
} from "../../../domain/entities/course.entity";
import {
  CourseMapper,
  CourseEnrollmentMapper,
} from "../../mappers/course.mapper";

@Injectable()
export class CourseMongoRepository implements ICourseRepository {
  constructor(@InjectModel("Course") private readonly model: Model<any>) {}

  async findAll(filters?: {
    qualificationOnly?: boolean;
    courseType?: string;
    hasCertification?: boolean;
  }): Promise<CourseEntity[]> {
    const q: Record<string, unknown> = {};
    if (filters?.qualificationOnly) q.isQualificationCourse = true;
    if (filters?.courseType) q.courseType = filters.courseType;
    if (filters?.hasCertification)
      q.certification = { $exists: true, $nin: [null, ""] };
    return (await this.model.find(q).sort({ createdAt: 1 }).lean().exec()).map(
      CourseMapper.toDomain,
    );
  }

  async findById(id: string): Promise<CourseEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).lean().exec();
    return doc ? CourseMapper.toDomain(doc) : null;
  }

  async findBySlug(slug: string): Promise<CourseEntity | null> {
    const doc = await this.model.findOne({ slug }).lean().exec();
    return doc ? CourseMapper.toDomain(doc) : null;
  }

  async save(entity: CourseEntity): Promise<CourseEntity> {
    const data = CourseMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return CourseMapper.toDomain(doc.toObject());
  }
}

@Injectable()
export class CourseEnrollmentMongoRepository implements ICourseEnrollmentRepository {
  constructor(
    @InjectModel("CourseEnrollment") private readonly model: Model<any>,
  ) {}

  async findByUserId(userId: string): Promise<CourseEnrollmentEntity[]> {
    return (
      await this.model
        .find({ userId: new Types.ObjectId(userId) })
        .sort({ updatedAt: -1 })
        .lean()
        .exec()
    ).map(CourseEnrollmentMapper.toDomain);
  }

  async findByUserAndCourse(
    userId: string,
    courseId: string,
  ): Promise<CourseEnrollmentEntity | null> {
    const doc = await this.model
      .findOne({
        userId: new Types.ObjectId(userId),
        courseId: new Types.ObjectId(courseId),
      })
      .lean()
      .exec();
    return doc ? CourseEnrollmentMapper.toDomain(doc) : null;
  }

  async findById(id: string): Promise<CourseEnrollmentEntity | null> {
    const doc = await this.model.findById(new Types.ObjectId(id)).lean().exec();
    return doc ? CourseEnrollmentMapper.toDomain(doc) : null;
  }

  async findAll(userId?: string): Promise<CourseEnrollmentEntity[]> {
    const q: Record<string, unknown> = {};
    if (userId) q.userId = new Types.ObjectId(userId);
    return (await this.model.find(q).sort({ updatedAt: -1 }).lean().exec()).map(
      CourseEnrollmentMapper.toDomain,
    );
  }

  async findCompletedByUser(userId: string): Promise<CourseEnrollmentEntity[]> {
    return (
      await this.model
        .find({
          userId: new Types.ObjectId(userId),
          status: "completed",
          progressPercent: 100,
        })
        .lean()
        .exec()
    ).map(CourseEnrollmentMapper.toDomain);
  }

  async save(entity: CourseEnrollmentEntity): Promise<CourseEnrollmentEntity> {
    const data = CourseEnrollmentMapper.toPersistence(entity);
    const doc = await this.model.create(data);
    return CourseEnrollmentMapper.toDomain(doc.toObject());
  }

  async update(
    entity: CourseEnrollmentEntity,
  ): Promise<CourseEnrollmentEntity> {
    const data = CourseEnrollmentMapper.toPersistence(entity);
    const { _id, ...rest } = data;
    await this.model.updateOne({ _id }, { $set: rest }).exec();
    return entity;
  }
}
