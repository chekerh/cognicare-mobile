import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import axios from 'axios';
import { CertificationTest } from './schemas/certification-test.schema';
import { CertificationAttempt } from './schemas/certification-attempt.schema';
import { VolunteersService } from '../volunteers/volunteers.service';
import { CoursesService } from '../courses/courses.service';

export interface QuestionForClient {
  index: number;
  type: 'mcq' | 'short_answer';
  text: string;
  options?: string[];
}

interface SubmitAnswerDto {
  questionIndex: number;
  value: string;
}

@Injectable()
export class CertificationTestService {
  private readonly logger = new Logger(CertificationTestService.name);
  private readonly geminiKey = process.env.GEMINI_API_KEY;
  private readonly geminiModel =
    process.env.PROGRESS_AI_MODEL?.trim() || 'gemini-2.0-flash';

  constructor(
    @InjectModel(CertificationTest.name)
    private readonly testModel: Model<CertificationTest>,
    @InjectModel(CertificationAttempt.name)
    private readonly attemptModel: Model<CertificationAttempt>,
    private readonly volunteersService: VolunteersService,
    private readonly coursesService: CoursesService,
  ) {}

  /**
   * Returns the certification test for the volunteer (questions without correct answers).
   * Requires: completed qualification course and approved application.
   * If already certified, returns { alreadyCertified: true }.
   */
  async getTest(userId: string): Promise<{
    alreadyCertified?: boolean;
    testId?: string;
    title?: string;
    questions?: QuestionForClient[];
    passingScorePercent?: number;
  }> {
    const app = await this.volunteersService.getOrCreateApplication(userId);
    const application = app as Record<string, unknown>;
    if (application?.trainingCertified === true) {
      return { alreadyCertified: true };
    }
    if (application?.status !== 'approved') {
      throw new BadRequestException(
        'Your volunteer application must be approved before taking the certification test.',
      );
    }
    const completed =
      await this.coursesService.hasCompletedQualificationCourse(userId);
    if (!completed) {
      throw new BadRequestException(
        'Complete a qualification course (100%) before taking the certification test.',
      );
    }

    const test = await this.testModel.findOne({ slug: 'default' }).exec();
    if (!test || !test.questions?.length) {
      throw new NotFoundException(
        'Certification test is not available. Please contact support.',
      );
    }

    const questions: QuestionForClient[] = test.questions.map((q, index) => {
      const out: QuestionForClient = {
        index,
        type: q.type,
        text: q.text,
      };
      if (q.type === 'mcq' && q.options?.length) {
        out.options = [...q.options];
      }
      return out;
    });

    return {
      testId: (test as unknown as { _id: Types.ObjectId })._id?.toString?.(),
      title: test.title,
      questions,
      passingScorePercent: test.passingScorePercent,
    };
  }

  /**
   * Submit answers, compute score, and if passed call completeCertification.
   */
  async submit(
    userId: string,
    answers: SubmitAnswerDto[],
  ): Promise<{
    passed: boolean;
    scorePercent: number;
    certified: boolean;
    totalQuestions: number;
    correctCount: number;
  }> {
    const test = await this.testModel.findOne({ slug: 'default' }).exec();
    if (!test || !test.questions?.length) {
      throw new NotFoundException('Certification test not found.');
    }

    const app = await this.volunteersService.getOrCreateApplication(userId);
    const application = app as Record<string, unknown>;
    if (application?.trainingCertified === true) {
      return {
        passed: true,
        scorePercent: 100,
        certified: true,
        totalQuestions: test.questions.length,
        correctCount: test.questions.length,
      };
    }

    let correctCount = 0;
    const answerMap = new Map(
      answers.map((a) => [a.questionIndex, a.value?.trim() ?? '']),
    );

    for (let i = 0; i < test.questions.length; i++) {
      const q = test.questions[i];
      const userValue = answerMap.get(i) ?? '';
      if (q.type === 'mcq') {
        const correctIndex = q.correctOptionIndex ?? -1;
        const option = q.options?.[correctIndex];
        if (option !== undefined && userValue === option) {
          correctCount++;
        }
      } else {
        const expected = (q.correctAnswer ?? '').trim().toLowerCase();
        const actual = userValue.toLowerCase().trim();
        if (expected && actual && actual === expected) {
          correctCount++;
        }
      }
    }

    const totalQuestions = test.questions.length;
    const scorePercent =
      totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 100) : 0;
    const passed = scorePercent >= (test.passingScorePercent ?? 80);

    await this.attemptModel.create({
      userId: new Types.ObjectId(userId),
      testId: (test as unknown as { _id: Types.ObjectId })._id,
      answers: answers.map((a) => ({ questionIndex: a.questionIndex, value: a.value })),
      scorePercent,
      passed,
      certified: false,
    });

    let certified = false;
    if (passed) {
      await this.volunteersService.completeCertification(userId);
      certified = true;
      const attempt = await this.attemptModel
        .findOne({ userId: new Types.ObjectId(userId) })
        .sort({ createdAt: -1 })
        .exec();
      if (attempt) {
        attempt.certified = true;
        await attempt.save();
      }
    }

    return {
      passed,
      scorePercent,
      certified,
      totalQuestions,
      correctCount,
    };
  }

  /**
   * AI-generated insights and recommendations for the volunteer (performance, next steps).
   */
  async getVolunteerInsights(userId: string): Promise<{
    summary: string;
    recommendations: string[];
  }> {
    const [app, enrollments, lastAttempt] = await Promise.all([
      this.volunteersService.getOrCreateApplication(userId),
      this.coursesService.myEnrollments(userId),
      this.attemptModel
        .findOne({ userId: new Types.ObjectId(userId) })
        .sort({ createdAt: -1 })
        .lean()
        .exec(),
    ]);
    const application = app as Record<string, unknown>;
    const completedEnrollments = (enrollments as Array<Record<string, unknown>>).filter(
      (e) => e.status === 'completed' && (e.progressPercent as number) >= 100,
    );
    const qualificationCompleted = completedEnrollments.some(
      (e) => (e.course as Record<string, unknown>)?.isQualificationCourse === true,
    );
    const lastAttemptData = lastAttempt as Record<string, unknown> | null;
    const context = {
      applicationStatus: application?.status,
      trainingCertified: application?.trainingCertified,
      completedCoursesCount: completedEnrollments.length,
      qualificationCourseCompleted: qualificationCompleted,
      lastTestScore: lastAttemptData?.scorePercent,
      lastTestPassed: lastAttemptData?.passed,
    };
    if (!this.geminiKey) {
      return {
        summary:
          'Résumé personnalisé non disponible (configuration API manquante). Continuez vos formations et passez le test de certification pour débloquer l\'Agenda et les Messages.',
        recommendations: [
          qualificationCompleted
            ? 'Passez le test de certification pour débloquer l\'Agenda et les Messages.'
            : 'Complétez une formation qualifiante à 100 %.',
          'Consultez le catalogue pour découvrir d\'autres formations.',
        ],
      };
    }
    const prompt = `Tu es un assistant bienveillant pour une plateforme de bénévoles accompagnant des enfants (dont TSA). Voici les données anonymisées d'un bénévole (JSON):
${JSON.stringify(context)}
Réponds UNIQUEMENT en JSON valide avec exactement ces clés (pas de markdown, pas de \`\`\`):
- "summary": une phrase courte et encourageante sur son profil (formation, certification).
- "recommendations": un tableau de 2 à 4 recommandations courtes et actionnables (ex: "Passer le test de certification", "Explorer les formations avancées"). En français.`;

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.geminiModel}:generateContent`;
      const res = await axios.post(
        url,
        {
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 1024,
          },
        },
        {
          params: { key: this.geminiKey },
          timeout: 15000,
          headers: { 'Content-Type': 'application/json' },
        },
      );
      const text =
        res.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';
      const cleaned = text
        .replace(/```json\s*/gi, '')
        .replace(/```\s*/g, '')
        .trim();
      const parsed = JSON.parse(cleaned);
      const summary =
        typeof parsed.summary === 'string'
          ? parsed.summary
          : 'Profil en cours de construction.';
      const recommendations = Array.isArray(parsed.recommendations)
        ? parsed.recommendations.filter((r: unknown) => typeof r === 'string')
        : [];
      return { summary, recommendations };
    } catch (err) {
      this.logger.warn(
        'Gemini volunteer insights failed: ' + (err as Error)?.message,
      );
      return {
        summary:
          'Profil en cours. Complétez vos formations et le test de certification pour des conseils personnalisés.',
        recommendations: [
          qualificationCompleted
            ? 'Passez le test de certification.'
            : 'Complétez une formation qualifiante.',
        ],
      };
    }
  }
}
