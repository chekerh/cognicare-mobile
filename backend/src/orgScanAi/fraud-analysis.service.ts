import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { OrgScanAiService } from './orgScanAi.service';
import { SimilarityService } from './similarity.service';
import { RiskService, ExtractedFields } from './risk.service';
import { DomainRiskService } from './domain-risk.service';
import {
  FraudAnalysis,
  FraudAnalysisDocument,
} from './schemas/fraud-analysis.schema';

export interface AnalysisInput {
  organizationId: string;
  pdfBuffer: Buffer;
  email?: string;
  websiteDomain?: string;
  originalPdfPath?: string;
}

export interface AnalysisResult {
  organizationId: string;
  fraudRisk: number;
  level: 'LOW' | 'MEDIUM' | 'HIGH';
  flags: string[];
  similarityScore: number;
  similarityRisk: 'LOW' | 'MEDIUM' | 'HIGH';
  extractedFields: ExtractedFields;
  documentInconsistencyScore: number;
  domainRiskScore: number;
  aiRawResponse: string;
  analysisId: string;
}

@Injectable()
export class FraudAnalysisService {
  private readonly logger = new Logger(FraudAnalysisService.name);

  constructor(
    @InjectModel(FraudAnalysis.name)
    private fraudAnalysisModel: Model<FraudAnalysisDocument>,
    private readonly orgScanAiService: OrgScanAiService,
    private readonly similarityService: SimilarityService,
    private readonly riskService: RiskService,
    private readonly domainRiskService: DomainRiskService,
  ) {}

  /**
   * Perform complete fraud analysis on organization documents
   */
  async analyzeOrganization(input: AnalysisInput): Promise<AnalysisResult> {
    this.logger.log(
      `Starting fraud analysis for organization: ${input.organizationId}`,
    );

    const allFlags: string[] = [];

    // Step 1: Extract text from PDF
    let extractedText: string;
    try {
      extractedText = await this.orgScanAiService.extractTextFromBuffer(
        input.pdfBuffer,
      );
      this.logger.log(`Extracted ${extractedText.length} characters from PDF`);
    } catch {
      throw new Error('Failed to extract text from PDF document');
    }

    // Step 2: Analyze with Gemini AI
    let aiResponse: string;
    try {
      aiResponse = await this.orgScanAiService.analyzeWithAI(extractedText);
    } catch {
      this.logger.error('Gemini AI analysis failed, using fallback analysis');
      aiResponse = JSON.stringify({
        organization_name: null,
        registration_number: null,
        issuing_authority: null,
        expiration_date: null,
        address: null,
        issues_found: ['AI analysis unavailable'],
        suspicious_elements: [],
        overall_assessment: 'suspicious',
      });
      allFlags.push('AI analysis service unavailable');
    }

    // Step 3: Parse extracted fields
    const extractedFields = this.riskService.parseExtractedFields(aiResponse);

    // Step 4: Calculate document inconsistency score
    const documentAnalysis = this.riskService.calculateDocumentInconsistency(
      aiResponse,
      extractedFields,
    );
    allFlags.push(...documentAnalysis.flags);

    // Step 5: Generate embedding and check similarity
    let embedding: number[] = [];
    let similarityResult: {
      similarityScore: number;
      similarityRisk: 'LOW' | 'MEDIUM' | 'HIGH';
    } = { similarityScore: 0, similarityRisk: 'LOW' };

    if (this.similarityService.isReady()) {
      try {
        embedding =
          await this.similarityService.generateEmbedding(extractedText);
        similarityResult =
          await this.similarityService.findMaxSimilarity(embedding);

        if (similarityResult.similarityRisk === 'HIGH') {
          allFlags.push(
            'High similarity to previous submission (potential template reuse)',
          );
        } else if (similarityResult.similarityRisk === 'MEDIUM') {
          allFlags.push('Moderate similarity to previous submissions');
        }
      } catch {
        this.logger.warn('Similarity analysis failed, continuing without it');
      }
    } else {
      this.logger.warn(
        'Similarity service not ready, skipping similarity check',
      );
    }

    // Step 6: Calculate domain risk
    const domainRisk = await this.domainRiskService.calculateDomainRisk(
      input.email,
      input.websiteDomain,
    );
    allFlags.push(...domainRisk.flags);

    // Step 7: Calculate final fraud risk
    const fraudRiskResult = this.riskService.calculateFraudRisk(
      documentAnalysis.score,
      similarityResult.similarityScore,
      domainRisk.score,
      allFlags,
    );

    // Step 8: Store in MongoDB
    const fraudAnalysis = new this.fraudAnalysisModel({
      organizationId: new Types.ObjectId(input.organizationId),
      extractedFields,
      aiRawResponse: aiResponse,
      fraudRiskScore: fraudRiskResult.fraudRisk,
      fraudRiskLevel: fraudRiskResult.level,
      similarityScore: similarityResult.similarityScore,
      similarityRisk: similarityResult.similarityRisk,
      documentInconsistencyScore: documentAnalysis.score,
      domainRiskScore: domainRisk.score,
      flags: fraudRiskResult.flags,
      originalPdfPath: input.originalPdfPath,
      emailDomain: input.email
        ? this.domainRiskService.extractDomain(input.email)
        : undefined,
      websiteDomain: input.websiteDomain,
      embedding,
      isRejected: false,
    });

    const savedAnalysis = await fraudAnalysis.save();
    this.logger.log(
      `Fraud analysis saved with ID: ${String(savedAnalysis._id)}`,
    );

    // Step 9: Return result
    return {
      organizationId: input.organizationId,
      fraudRisk: fraudRiskResult.fraudRisk,
      level: fraudRiskResult.level,
      flags: fraudRiskResult.flags,
      similarityScore: similarityResult.similarityScore,
      similarityRisk: similarityResult.similarityRisk,
      extractedFields,
      documentInconsistencyScore: documentAnalysis.score,
      domainRiskScore: domainRisk.score,
      aiRawResponse: aiResponse,
      analysisId: savedAnalysis._id.toString(),
    };
  }

  /**
   * Get analysis history for an organization
   */
  async getOrganizationAnalyses(
    organizationId: string,
  ): Promise<FraudAnalysisDocument[]> {
    return this.fraudAnalysisModel
      .find({ organizationId: new Types.ObjectId(organizationId) })
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Get a specific analysis by ID
   */
  async getAnalysisById(
    analysisId: string,
  ): Promise<FraudAnalysisDocument | null> {
    return this.fraudAnalysisModel.findById(analysisId).exec();
  }

  /**
   * Mark an analysis as rejected (for future similarity detection)
   */
  async markAsRejected(
    analysisId: string,
    reviewedBy: string,
    notes?: string,
  ): Promise<FraudAnalysisDocument | null> {
    return this.fraudAnalysisModel
      .findByIdAndUpdate(
        analysisId,
        {
          isRejected: true,
          reviewedAt: new Date(),
          reviewedBy,
          reviewNotes: notes,
        },
        { new: true },
      )
      .exec();
  }

  /**
   * Mark an analysis as approved
   */
  async markAsApproved(
    analysisId: string,
    reviewedBy: string,
    notes?: string,
  ): Promise<FraudAnalysisDocument | null> {
    return this.fraudAnalysisModel
      .findByIdAndUpdate(
        analysisId,
        {
          isRejected: false,
          reviewedAt: new Date(),
          reviewedBy,
          reviewNotes: notes,
        },
        { new: true },
      )
      .exec();
  }

  /**
   * Get all high-risk submissions for admin review
   */
  async getHighRiskSubmissions(): Promise<FraudAnalysisDocument[]> {
    return this.fraudAnalysisModel
      .find({
        fraudRiskLevel: 'HIGH',
        reviewedAt: { $exists: false },
      })
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Get all pending submissions for admin review
   */
  async getPendingReviews(): Promise<FraudAnalysisDocument[]> {
    return this.fraudAnalysisModel
      .find({
        reviewedAt: { $exists: false },
      })
      .sort({ fraudRiskScore: -1, createdAt: -1 })
      .exec();
  }

  /**
   * Get statistics for admin dashboard
   */
  async getAnalyticsStats(): Promise<{
    total: number;
    highRisk: number;
    mediumRisk: number;
    lowRisk: number;
    pending: number;
    rejected: number;
  }> {
    const [total, highRisk, mediumRisk, lowRisk, pending, rejected] =
      await Promise.all([
        this.fraudAnalysisModel.countDocuments(),
        this.fraudAnalysisModel.countDocuments({ fraudRiskLevel: 'HIGH' }),
        this.fraudAnalysisModel.countDocuments({ fraudRiskLevel: 'MEDIUM' }),
        this.fraudAnalysisModel.countDocuments({ fraudRiskLevel: 'LOW' }),
        this.fraudAnalysisModel.countDocuments({
          reviewedAt: { $exists: false },
        }),
        this.fraudAnalysisModel.countDocuments({ isRejected: true }),
      ]);

    return { total, highRisk, mediumRisk, lowRisk, pending, rejected };
  }
}
