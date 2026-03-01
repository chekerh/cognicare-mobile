import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import * as fs from "fs";
import * as path from "path";
import { TrainingCourse } from "./schemas/training.schema";
import { TrainingEnrollment } from "./schemas/training.schema";
import { CreateTrainingCourseDto } from "./dto/create-training-course.dto";
import { UpdateTrainingCourseDto } from "./dto/update-training-course.dto";
import { ApproveTrainingCourseDto } from "./dto/approve-training-course.dto";
import { SetTrainingCertifiedFromTrainingCoursesUseCase } from "../volunteers/application/use-cases/volunteer.use-cases";

const QUIZ_PASS_THRESHOLD_PERCENT = 80;

interface QuizQuestionRecord {
  question: string;
  options?: string[];
  correctIndex?: number;
  correctAnswer?: string;
  order?: number;
  type?: "mcq" | "true_false" | "fill_blank";
}

export interface QuizReviewItem {
  questionIndex: number;
  correctIndex?: number;
  correctOptionText?: string;
  correctAnswer?: string;
  userSelectedIndex?: number;
  userAnswer?: string;
  isCorrect: boolean;
}

@Injectable()
export class TrainingService {
  constructor(
    @InjectModel(TrainingCourse.name)
    private readonly courseModel: Model<TrainingCourse>,
    @InjectModel(TrainingEnrollment.name)
    private readonly enrollmentModel: Model<TrainingEnrollment>,
    @Inject(forwardRef(() => SetTrainingCertifiedFromTrainingCoursesUseCase))
    private readonly setTrainingCertifiedUC: SetTrainingCertifiedFromTrainingCoursesUseCase,
  ) {}

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

  async getById(courseId: string, admin = false) {
    const course = await this.courseModel.findById(courseId).lean().exec();
    if (!course) throw new NotFoundException("Training course not found");
    const c = course as Record<string, unknown>;
    if (!admin && !c.approved) throw new NotFoundException("Course not found");
    return this.toCourseResponse(c, admin, !admin);
  }

  async seedCoursesIfEmpty(): Promise<void> {
    const count = await this.courseModel.countDocuments().exec();
    if (count > 0) return;
    const seedPath = path.join(
      process.cwd(),
      "data",
      "training-courses-seed.json",
    );
    if (!fs.existsSync(seedPath)) return;
    try {
      const raw = fs.readFileSync(seedPath, "utf-8");
      const courses = JSON.parse(raw) as CreateTrainingCourseDto[];
      if (!Array.isArray(courses) || courses.length === 0) return;
      await this.courseModel.insertMany(courses);
    } catch {
      // seed is optional
    }
  }

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

  async update(courseId: string, dto: UpdateTrainingCourseDto) {
    const course = await this.courseModel
      .findByIdAndUpdate(
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
    if (!course) throw new NotFoundException("Training course not found");
    return this.toCourseResponse(
      course as unknown as Record<string, unknown>,
      true,
      false,
    );
  }

  async approve(
    courseId: string,
    adminId: string,
    dto: ApproveTrainingCourseDto,
  ) {
    const course = await this.courseModel
      .findByIdAndUpdate(
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
    if (!course) throw new NotFoundException("Training course not found");
    return this.toCourseResponse(
      course as unknown as Record<string, unknown>,
      true,
      false,
    );
  }

  async enroll(userId: string, courseId: string) {
    const course = await this.courseModel
      .findOne({ _id: courseId, approved: true })
      .exec();
    if (!course) throw new NotFoundException("Course not found");
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

  async getMyEnrollments(userId: string) {
    const list = await this.enrollmentModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate("courseId", "title description order")
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
        (o.courseId as Types.ObjectId)?.toString?.() ?? "",
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
          ? { title: c.title, description: c.description, order: c.order }
          : null,
      };
    });
  }

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
    if (!enrollment) throw new NotFoundException("Enrollment not found");
    enrollment.contentCompleted = true;
    enrollment.progressPercent = Math.max(
      enrollment.progressPercent,
      enrollment.quizPassed ? 100 : 50,
    );
    await enrollment.save();
    return this.getMyEnrollments(userId);
  }

  async submitQuiz(
    userId: string,
    courseId: string,
    answers: number[],
    textAnswers?: string[],
  ): Promise<{
    scorePercent: number;
    passed: boolean;
    correct: number;
    total: number;
    enrollments: Awaited<ReturnType<typeof this.getMyEnrollments>>;
    review: QuizReviewItem[];
  }> {
    const course = await this.courseModel
      .findOne({ _id: courseId, approved: true })
      .lean()
      .exec();
    if (!course) throw new NotFoundException("Course not found");
    const quiz = (course as Record<string, unknown>).quiz as QuizQuestionRecord[] | undefined;
    if (!Array.isArray(quiz) || quiz.length === 0) {
      throw new BadRequestException("Course has no quiz");
    }
    if (answers.length !== quiz.length) {
      throw new BadRequestException(
        `Expected ${quiz.length} answers, got ${answers.length}`,
      );
    }
    const review: QuizReviewItem[] = [];
    let correct = 0;
    for (let i = 0; i < quiz.length; i++) {
      const q = quiz[i];
      const type = q.type ?? "mcq";
      const selected = answers[i];
      const textAnswer =
        textAnswers && textAnswers[i] !== undefined ? String(textAnswers[i]).trim() : "";

      let isCorrect = false;
      if (type === "fill_blank") {
        const expected = (q.correctAnswer ?? "").trim().toLowerCase();
        const actual = textAnswer.toLowerCase();
        isCorrect = !!expected && actual === expected;
        review.push({
          questionIndex: i,
          correctAnswer: q.correctAnswer,
          userAnswer: textAnswer || undefined,
          isCorrect,
        });
      } else {
        const options = q.options ?? [];
        const correctIndex = q.correctIndex ?? 0;
        const valid = selected >= 0 && selected < options.length;
        isCorrect = valid && selected === correctIndex;
        review.push({
          questionIndex: i,
          correctIndex,
          correctOptionText: options[correctIndex],
          userSelectedIndex: selected >= 0 ? selected : undefined,
          isCorrect,
        });
      }
      if (isCorrect) correct++;
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
    if (!enrollment) throw new NotFoundException("Enrollment not found");

    enrollment.quizAttempts = (enrollment.quizAttempts ?? 0) + 1;
    enrollment.quizScorePercent = scorePercent;
    enrollment.quizPassed = passed;
    if (passed) {
      enrollment.progressPercent = 100;
      enrollment.completedAt = new Date();
    }
    await enrollment.save();

    if (passed) {
      const allPassed = await this.haveAllApprovedTrainingCoursesPassed(userId);
      if (allPassed) {
        await this.setTrainingCertifiedUC.execute(userId);
      }
    }

    return {
      scorePercent,
      passed,
      correct,
      total: quiz.length,
      enrollments: await this.getMyEnrollments(userId),
      review,
    };
  }

  private async haveAllApprovedTrainingCoursesPassed(userId: string): Promise<boolean> {
    const courses = await this.courseModel
      .find({ approved: true })
      .sort({ order: 1 })
      .lean()
      .exec();
    if (courses.length === 0) return false;
    const enrollments = await this.enrollmentModel
      .find({ userId: new Types.ObjectId(userId) })
      .lean()
      .exec();
    const passedByCourse = new Set(
      (enrollments as Record<string, unknown>[])
        .filter((e) => e.progressPercent === 100 && e.quizPassed === true)
        .map((e) => (e.courseId as Types.ObjectId)?.toString?.()),
    );
    for (const c of courses) {
      const id = (c as { _id: Types.ObjectId })._id.toString();
      if (!passedByCourse.has(id)) return false;
    }
    return true;
  }

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
        .filter((e) => e.progressPercent === 100 && e.quizPassed === true)
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
    const quizRaw = (c.quiz ?? []) as QuizQuestionRecord[];
    const quiz = stripQuizAnswers
      ? quizRaw.map((q) => ({
          question: q.question,
          options: q.options ?? [],
          order: q.order ?? 0,
          type: q.type,
        }))
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
