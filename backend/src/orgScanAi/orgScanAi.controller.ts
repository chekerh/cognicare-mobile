import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  UseInterceptors,
  UploadedFile,
  UseGuards,
  Request,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { OrgScanAiService } from './orgScanAi.service';
import { FraudAnalysisService } from './fraud-analysis.service';
import { SimilarityService } from './similarity.service';
import {
  PendingOrganization,
  PendingOrganizationDocument,
} from '../organization/schemas/pending-organization.schema';
import axios from 'axios';
import {
  AnalyzeOrganizationDto,
  ReviewAnalysisDto,
  FraudAnalysisResponse,
  AnalysisStatsResponse,
} from './dto/fraud-analysis.dto';

@ApiTags('Organization Document Scanner AI')
@Controller('org-scan-ai')
export class OrgScanAiController {
  constructor(
    private readonly orgScanAiService: OrgScanAiService,
    private readonly fraudAnalysisService: FraudAnalysisService,
    private readonly similarityService: SimilarityService,
    @InjectModel(PendingOrganization.name)
    private readonly pendingOrganizationModel: Model<PendingOrganizationDocument>,
  ) {}

  @Post('analyze')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary', description: 'PDF document' },
        organizationId: { type: 'string', description: 'Organization ID' },
        email: { type: 'string', description: 'Organization email (optional)' },
        websiteDomain: {
          type: 'string',
          description: 'Website domain (optional)',
        },
      },
      required: ['file', 'organizationId'],
    },
  })
  @ApiOperation({
    summary: 'Analyze organization document for fraud detection',
    description:
      'Uploads a PDF document and performs comprehensive fraud analysis including AI text extraction, similarity detection, and risk scoring',
  })
  @ApiResponse({ status: 200, type: FraudAnalysisResponse })
  async analyzeOrganization(
    @UploadedFile()
    file: {
      buffer: Buffer;
      mimetype: string;
      originalname: string;
      size: number;
    },
    @Body() dto: AnalyzeOrganizationDto,
  ): Promise<FraudAnalysisResponse> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    if (file.mimetype !== 'application/pdf') {
      throw new BadRequestException('Only PDF files are accepted');
    }

    const result = await this.fraudAnalysisService.analyzeOrganization({
      organizationId: dto.organizationId,
      pdfBuffer: file.buffer,
      email: dto.email,
      websiteDomain: dto.websiteDomain,
      originalPdfPath: file.originalname,
    });

    return {
      organizationId: result.organizationId,
      analysisId: result.analysisId,
      fraudRisk: result.fraudRisk,
      level: result.level,
      flags: result.flags,
      similarityScore: result.similarityScore,
      similarityRisk: result.similarityRisk,
      extractedFields: result.extractedFields,
      documentInconsistencyScore: result.documentInconsistencyScore,
      domainRiskScore: result.domainRiskScore,
      timestamp: new Date().toISOString(),
    };
  }

  @Get('analysis/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get a specific fraud analysis by ID' })
  async getAnalysis(@Param('id') id: string) {
    const analysis = await this.fraudAnalysisService.getAnalysisById(id);
    if (!analysis) {
      throw new BadRequestException('Analysis not found');
    }
    return analysis;
  }

  @Get('organization/:orgId/analyses')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all analyses for an organization' })
  async getOrganizationAnalyses(@Param('orgId') orgId: string) {
    return this.fraudAnalysisService.getOrganizationAnalyses(orgId);
  }

  @Patch('analysis/:id/reject')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark analysis as rejected (admin only)' })
  async rejectAnalysis(
    @Param('id') id: string,
    @Body() dto: ReviewAnalysisDto,
    @Request() req: { user?: { userId?: string; _id?: string } },
  ) {
    const userId = req.user?.userId ?? req.user?._id ?? 'unknown';
    const result = await this.fraudAnalysisService.markAsRejected(
      id,
      String(userId),
      dto.notes,
    );

    if (!result) {
      throw new BadRequestException('Analysis not found');
    }

    return {
      message: 'Analysis marked as rejected',
      analysis: result,
    };
  }

  @Patch('analysis/:id/approve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark analysis as approved (admin only)' })
  async approveAnalysis(
    @Param('id') id: string,
    @Body() dto: ReviewAnalysisDto,
    @Request() req: { user?: { userId?: string; _id?: string } },
  ) {
    const userId = req.user?.userId ?? req.user?._id ?? 'unknown';
    const result = await this.fraudAnalysisService.markAsApproved(
      id,
      String(userId),
      dto.notes,
    );

    if (!result) {
      throw new BadRequestException('Analysis not found');
    }

    return {
      message: 'Analysis marked as approved',
      analysis: result,
    };
  }

  @Get('admin/high-risk')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all high-risk submissions pending review' })
  async getHighRiskSubmissions() {
    return this.fraudAnalysisService.getHighRiskSubmissions();
  }

  @Get('admin/pending')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all submissions pending review' })
  async getPendingReviews() {
    return this.fraudAnalysisService.getPendingReviews();
  }

  @Get('admin/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get fraud analysis statistics' })
  @ApiResponse({ status: 200, type: AnalysisStatsResponse })
  async getStats(): Promise<AnalysisStatsResponse> {
    return this.fraudAnalysisService.getAnalyticsStats();
  }

  @Get('health')
  @ApiOperation({
    summary: 'Check AI services health',
    description: 'Returns the status of Gemini AI and embedding model',
  })
  async checkHealth() {
    const geminiConfigured = this.orgScanAiService.isConfigured();
    const geminiHealthy = geminiConfigured
      ? await this.orgScanAiService.checkGeminiHealth()
      : false;
    const similarityReady = this.similarityService.isReady();

    return {
      gemini: {
        configured: geminiConfigured,
        available: geminiHealthy,
        model: 'gemma-3-4b-it',
      },
      similarity: {
        available: similarityReady,
        model: 'Xenova/all-MiniLM-L6-v2',
      },
      status:
        geminiConfigured && geminiHealthy && similarityReady
          ? 'OK'
          : 'DEGRADED',
      timestamp: new Date().toISOString(),
    };
  }

  // Legacy endpoint for backward compatibility
  @Post('analyze-document')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({
    summary: 'Simple document analysis (legacy)',
    deprecated: true,
  })
  async analyzeDocumentLegacy(
    @UploadedFile()
    file: {
      buffer: Buffer;
      mimetype: string;
      originalname: string;
      size: number;
    },
  ) {
    if (!file) {
      return { error: 'No file uploaded' };
    }

    const result = await this.orgScanAiService.analyzeDocumentFromBuffer(
      file.buffer,
    );

    let riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
    if (result.riskScore > 0.7) {
      riskLevel = 'HIGH';
    } else if (result.riskScore > 0.4) {
      riskLevel = 'MEDIUM';
    } else {
      riskLevel = 'LOW';
    }

    return {
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype,
      analysis: result.analysis,
      riskScore: result.riskScore,
      riskLevel,
      timestamp: new Date().toISOString(),
    };
  }

  @Post('rescan/:pendingOrgId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Rescan certificate for a pending organization',
    description:
      'Downloads the certificate from Cloudinary and re-runs AI fraud analysis for a pending organization',
  })
  @ApiResponse({ status: 200, type: FraudAnalysisResponse })
  async rescanPendingOrganization(
    @Param('pendingOrgId') pendingOrgId: string,
  ): Promise<FraudAnalysisResponse> {
    // Fetch pending organization
    const pendingOrg: PendingOrganizationDocument | null =
      await this.pendingOrganizationModel.findById(pendingOrgId);

    if (!pendingOrg) {
      throw new NotFoundException('Pending organization not found');
    }

    if (!pendingOrg.certificateUrl) {
      throw new BadRequestException(
        'No certificate URL found for this organization',
      );
    }

    // Download PDF from Cloudinary
    let pdfBuffer: Buffer;
    try {
      const response = await axios.get<ArrayBuffer>(
        pendingOrg.certificateUrl as string,
        {
          responseType: 'arraybuffer',
        },
      );
      pdfBuffer = Buffer.from(response.data);
    } catch {
      throw new BadRequestException(
        'Failed to download certificate from Cloudinary',
      );
    }

    // Perform fraud analysis
    const result = await this.fraudAnalysisService.analyzeOrganization({
      organizationId: pendingOrgId,
      pdfBuffer,
      email: pendingOrg.leaderEmail,
      websiteDomain: undefined,
      originalPdfPath: pendingOrg.certificateUrl as string,
    });

    return {
      organizationId: result.organizationId,
      analysisId: result.analysisId,
      fraudRisk: result.fraudRisk,
      level: result.level,
      flags: result.flags,
      similarityScore: result.similarityScore,
      similarityRisk: result.similarityRisk,
      extractedFields: result.extractedFields,
      documentInconsistencyScore: result.documentInconsistencyScore,
      domainRiskScore: result.domainRiskScore,
      timestamp: new Date().toISOString(),
    };
  }
}
