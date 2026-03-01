import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as fs from 'fs';
import * as path from 'path';
import { TrainingCourse } from './schemas/training-course.schema';
import { TrainingEnrollment } from './schemas/training-enrollment.schema';
import { CreateTrainingCourseDto } from './dto/create-training-course.dto';
import { UpdateTrainingCourseDto } from './dto/update-training-course.dto';
import { ApproveTrainingCourseDto } from './dto/approve-training-course.dto';

const QUIZ_PASS_THRESHOLD_PERCENT = 70;

@Injectable()
export class TrainingService {
  constructor(
    @InjectModel(TrainingCourse.name)
    private readonly courseModel: Model<TrainingCourse>,
    @InjectModel(TrainingEnrollment.name)
    private readonly enrollmentModel: Model<TrainingEnrollment>,
  ) {}

  /** List courses approved for app (caregivers) — only approved, ordered; quiz answers stripped */
  async listApproved() {
    const list = await this.courseModel
      .find({ approved: true })
      .sort({ order: 1, createdAt: 1 })
      .lean()
      .exec();
    return list.map((c) =>
      this.toCourseResponse(c as Record<string, unknown>, false, true),
    );
  }

  /** Admin: list all courses including unapproved */
  async listAll() {
    const list = await this.courseModel
      .find({})
      .sort({ order: 1, createdAt: 1 })
      .lean()
      .exec();
    return list.map((c) =>
      this.toCourseResponse(c as Record<string, unknown>, true, false),
    );
  }

  /** Get one course by id; only approved for non-admin; strip quiz answers for app */
  async getById(courseId: string, admin = false) {
    const course = await this.courseModel.findById(courseId).lean().exec();
    if (!course) throw new NotFoundException('Training course not found');
    const c = course as Record<string, unknown>;
    if (!admin && !c.approved) throw new NotFoundException('Course not found');
    return this.toCourseResponse(c, admin, !admin);
  }

  /** Seed the 3 generated courses (from scraped/official content) if collection is empty */
  async seedCoursesIfEmpty(): Promise<void> {
    const count = await this.courseModel.countDocuments().exec();
    if (count > 0) return;
    const seedPath = path.join(process.cwd(), 'data', 'training-courses-seed.json');
    if (!fs.existsSync(seedPath)) return;
    try {
      const raw = fs.readFileSync(seedPath, 'utf-8');
      const courses = JSON.parse(raw) as CreateTrainingCourseDto[];
      if (!Array.isArray(courses) || courses.length === 0) return;
      await this.courseModel.insertMany(courses);
    } catch {
      // ignore: seed is optional
    }
  }

  /** Create course (admin or scraper) */
  async create(dto: CreateTrainingCourseDto) {
    const created = await this.courseModel.create({
      title: dto.title,
      description: dto.description,
      contentSections: dto.contentSections ?? [],
      sourceUrl: dto.sourceUrl,
      topics: dto.topics ?? [],
      quiz: dto.quiz ?? [],
      approved: dto.approved ?? false,
      order: dto.order ?? 0,
    });
    return this.toCourseResponse(
      created.toObject() as unknown as Record<string, unknown>,
      true,
      false,
    );
  }

  /** Update course (admin) */
  async update(courseId: string, dto: UpdateTrainingCourseDto) {
    const course = await this.courseModel.findByIdAndUpdate(
      courseId,
      {
        $set: {
          ...(dto.title != null && { title: dto.title }),
          ...(dto.description != null && { description: dto.description }),
          ...(dto.contentSections != null && {
            contentSections: dto.contentSections,
          }),
          ...(dto.sourceUrl != null && { sourceUrl: dto.sourceUrl }),
          ...(dto.topics != null && { topics: dto.topics }),
          ...(dto.quiz != null && { quiz: dto.quiz }),
          ...(dto.order != null && { order: dto.order }),
        },
      },
      { new: true },
    )
      .lean()
      .exec();
    if (!course) throw new NotFoundException('Training course not found');
    return this.toCourseResponse(
      course as unknown as Record<string, unknown>,
      true,
      false,
    );
  }

  /** Approve or reject course (admin) */
  async approve(
    courseId: string,
    adminId: string,
    dto: ApproveTrainingCourseDto,
  ) {
    const course = await this.courseModel.findByIdAndUpdate(
      courseId,
      {
        $set: {
          approved: dto.approved,
          professionalComments: dto.professionalComments,
          approvedBy: new Types.ObjectId(adminId),
          approvedAt: new Date(),
        },
      },
      { new: true },
    )
      .lean()
      .exec();
    if (!course) throw new NotFoundException('Training course not found');
    return this.toCourseResponse(
      course as unknown as Record<string, unknown>,
      true,
      false,
    );
  }

  /** Enroll user in a course (start training) */
  async enroll(userId: string, courseId: string) {
    const course = await this.courseModel
      .findOne({ _id: courseId, approved: true })
      .exec();
    if (!course) throw new NotFoundException('Course not found');
    const existing = await this.enrollmentModel
      .findOne({
        userId: new Types.ObjectId(userId),
        courseId: new Types.ObjectId(courseId),
      })
      .exec();
    if (existing) return this.getMyEnrollments(userId);
    await this.enrollmentModel.create({
      userId: new Types.ObjectId(userId),
      courseId: new Types.ObjectId(courseId),
      progressPercent: 0,
      contentCompleted: false,
      quizPassed: false,
      quizAttempts: 0,
    });
    return this.getMyEnrollments(userId);
  }

  /** Get my enrollments with course summary */
  async getMyEnrollments(userId: string) {
    const list = await this.enrollmentModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('courseId', 'title description order')
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    const courseIds = list.map(
      (e) => (e as Record<string, unknown>).courseId as Types.ObjectId,
    );
    const courses = await this.courseModel
      .find({ _id: { $in: courseIds }, approved: true })
      .lean()
      .exec();
    const courseMap = new Map(
      courses.map((c) => [(c as { _id: Types.ObjectId })._id.toString(), c]),
    );
    return list.map((e) => {
      const o = e as Record<string, unknown>;
      const c = courseMap.get(
        (o.courseId as Types.ObjectId)?.toString?.() ?? '',
      ) as Record<string, unknown> | undefined;
      return {
        id: (o._id as { toString(): string })?.toString?.(),
        courseId: (o.courseId as Types.ObjectId)?.toString?.(),
        progressPercent: o.progressPercent,
        contentCompleted: o.contentCompleted,
        quizPassed: o.quizPassed,
        quizScorePercent: o.quizScorePercent,
        quizAttempts: o.quizAttempts,
        completedAt: o.completedAt,
        course: c
          ? {
              title: c.title,
              description: c.description,
              order: c.order,
            }
          : null,
      };
    });
  }

  /** Mark content as completed (user finished reading). Auto-enrolls if not yet enrolled. */
  async markContentCompleted(userId: string, courseId: string) {
    let enrollment = await this.enrollmentModel
      .findOne({
        userId: new Types.ObjectId(userId),
        courseId: new Types.ObjectId(courseId),
      })
      .exec();
    if (!enrollment) {
      await this.enroll(userId, courseId);
      enrollment = await this.enrollmentModel
        .findOne({
          userId: new Types.ObjectId(userId),
          courseId: new Types.ObjectId(courseId),
        })
        .exec();
    }
    if (!enrollment) throw new NotFoundException('Enrollment not found');
    enrollment.contentCompleted = true;
    enrollment.progressPercent = Math.max(
      enrollment.progressPercent,
      enrollment.quizPassed ? 100 : 50,
    );
    await enrollment.save();
    return this.getMyEnrollments(userId);
  }

  /** Submit quiz answers and record score */
  async submitQuiz(userId: string, courseId: string, answers: number[]) {
    const course = await this.courseModel
      .findOne({ _id: courseId, approved: true })
      .lean()
      .exec();
    if (!course) throw new NotFoundException('Course not found');
    const quiz = (course as Record<string, unknown>).quiz as
      | { question: string; options: string[]; correctIndex: number }[]
      | undefined;
    if (!Array.isArray(quiz) || quiz.length === 0) {
      throw new BadRequestException('Course has no quiz');
    }
    if (answers.length !== quiz.length) {
      throw new BadRequestException(
        `Expected ${quiz.length} answers, got ${answers.length}`,
      );
    }
    let correct = 0;
    for (let i = 0; i < quiz.length; i++) {
      const q = quiz[i];
      const selected = answers[i];
      if (
        selected >= 0 &&
        selected < (q.options?.length ?? 0) &&
        selected === q.correctIndex
      ) {
        correct++;
      }
    }
    const scorePercent = Math.round((correct / quiz.length) * 100);
    const passed = scorePercent >= QUIZ_PASS_THRESHOLD_PERCENT;

    let enrollment = await this.enrollmentModel
      .findOne({
        userId: new Types.ObjectId(userId),
        courseId: new Types.ObjectId(courseId),
      })
      .exec();
    if (!enrollment) {
      await this.enroll(userId, courseId);
      enrollment = await this.enrollmentModel
        .findOne({
          userId: new Types.ObjectId(userId),
          courseId: new Types.ObjectId(courseId),
        })
        .exec();
    }
    if (!enrollment) throw new NotFoundException('Enrollment not found');

    enrollment.quizAttempts = (enrollment.quizAttempts ?? 0) + 1;
    enrollment.quizScorePercent = scorePercent;
    enrollment.quizPassed = passed;
    if (passed) {
      enrollment.progressPercent = 100;
      enrollment.completedAt = new Date();
    }
    await enrollment.save();

    return {
      scorePercent,
      passed,
      correct,
      total: quiz.length,
      enrollments: await this.getMyEnrollments(userId),
    };
  }

  /** Check if user can access next course (previous completed + quiz passed) */
  async getNextUnlockedCourseId(userId: string): Promise<string | null> {
    const enrollments = await this.enrollmentModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: 1 })
      .lean()
      .exec();
    const courses = await this.courseModel
      .find({ approved: true })
      .sort({ order: 1 })
      .lean()
      .exec();
    const completedIds = new Set(
      (enrollments as Record<string, unknown>[])
        .filter(
          (e) =>
            e.progressPercent === 100 &&
            e.quizPassed === true,
        )
        .map((e) => (e.courseId as Types.ObjectId)?.toString?.()),
    );
    for (const c of courses) {
      const id = (c as { _id: Types.ObjectId })._id.toString();
      if (!completedIds.has(id)) return id;
    }
    return null;
  }

  private toCourseResponse(
    c: Record<string, unknown>,
    includeApproval = false,
    stripQuizAnswers = true,
  ) {
    const quizRaw = (c.quiz ?? []) as { question: string; options: string[]; correctIndex?: number; order?: number }[];
    const quiz = stripQuizAnswers
      ? quizRaw.map((q) => ({ question: q.question, options: q.options ?? [], order: q.order ?? 0 }))
      : quizRaw;
    const out: Record<string, unknown> = {
      id: (c._id as { toString(): string })?.toString?.(),
      title: c.title,
      description: c.description,
      contentSections: c.contentSections ?? [],
      sourceUrl: c.sourceUrl,
      topics: c.topics ?? [],
      quiz,
      order: c.order ?? 0,
    };
    if (includeApproval) {
      out.approved = c.approved;
      out.approvedBy = (c.approvedBy as Types.ObjectId)?.toString?.();
      out.approvedAt = c.approvedAt;
      out.professionalComments = c.professionalComments;
    }
    return out;
  }
}
