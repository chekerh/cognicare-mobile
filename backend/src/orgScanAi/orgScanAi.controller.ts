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
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import {
  PendingOrganization,
  PendingOrganizationDocument,
} from '../organization/schemas/pending-organization.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
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
    private readonly cloudinaryService: CloudinaryService,
    @InjectModel(PendingOrganization.name)
    private readonly pendingOrganizationModel: Model<PendingOrganizationDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
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

    // Get the pending organization to find the user who created it
    const pendingOrg = await this.pendingOrganizationModel.findById(
      result.organizationId,
    );

    if (pendingOrg && pendingOrg.requestedBy) {
      // Delete the organization leader's user account
      try {
        await this.userModel.findByIdAndDelete(pendingOrg.requestedBy);
        console.log(
          `[REJECT] Deleted user account for rejected organization: ${String(pendingOrg.requestedBy)}`,
        );
      } catch (error) {
        console.error(
          `[REJECT] Failed to delete user account: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
        // Don't throw - analysis is already rejected, just log the error
      }
    }

    return {
      message: 'Analysis marked as rejected and user account deleted',
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

  @Get('organization/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get pending organization details',
    description: 'Retrieve pending organization information by ID',
  })
  async getPendingOrganization(@Param('id') id: string) {
    const pendingOrg = await this.pendingOrganizationModel.findById(id);

    if (!pendingOrg) {
      throw new NotFoundException('Pending organization not found');
    }

    return {
      id: pendingOrg._id,
      organizationName: pendingOrg.organizationName,
      description: pendingOrg.description,
      leaderEmail: pendingOrg.leaderEmail,
      leaderFullName: pendingOrg.leaderFullName,
      requestedBy: pendingOrg.requestedBy,
      certificateUrl: pendingOrg.certificateUrl,
      status: pendingOrg.status,
      rejectionReason: pendingOrg.rejectionReason,
      reviewedBy: pendingOrg.reviewedBy,
      reviewedAt: pendingOrg.reviewedAt,
      createdAt: (pendingOrg as any).createdAt,
      updatedAt: (pendingOrg as any).updatedAt,
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
    console.log('[RESCAN] Certificate URL:', pendingOrg.certificateUrl);
    let pdfBuffer: Buffer;
    try {
      const response = await axios.get<ArrayBuffer>(pendingOrg.certificateUrl, {
        responseType: 'arraybuffer',
        headers: {
          Accept: 'application/pdf',
        },
      });
      pdfBuffer = Buffer.from(response.data);
      console.log(
        '[RESCAN] Downloaded PDF buffer size:',
        pdfBuffer.length,
        'bytes',
      );

      // Validate PDF header (should start with %PDF-)
      const pdfHeader = pdfBuffer.toString('utf8', 0, 5);
      if (!pdfHeader.startsWith('%PDF-')) {
        console.error('[RESCAN] Invalid PDF header:', pdfHeader);

        // Detect actual file type from magic bytes
        let detectedType = 'unknown';
        const hexHeader = pdfBuffer.toString('hex', 0, 8).toUpperCase();

        if (hexHeader.startsWith('89504E47')) {
          detectedType = 'PNG image';
        } else if (hexHeader.startsWith('FFD8FF')) {
          detectedType = 'JPEG image';
        } else if (hexHeader.startsWith('47494638')) {
          detectedType = 'GIF image';
        } else if (hexHeader.startsWith('424D')) {
          detectedType = 'BMP image';
        } else if (hexHeader.startsWith('25504446')) {
          detectedType = 'PDF (corrupted)';
        }

        throw new BadRequestException(
          `The uploaded certificate is not a valid PDF document (detected: ${detectedType}). ` +
            `The organization leader uploaded an invalid file during signup. ` +
            `Please reject this request and ask them to re-register with a proper PDF certificate, ` +
            `or contact support to manually upload a valid certificate.`,
        );
      }
      console.log('[RESCAN] Valid PDF header detected:', pdfHeader);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error('[RESCAN] Failed to download certificate:', errorMessage);
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(
        `Failed to download certificate from Cloudinary: ${errorMessage}`,
      );
    }

    // Perform fraud analysis
    console.log(
      '[RESCAN] Starting fraud analysis for pending org:',
      pendingOrgId,
    );
    const result = await this.fraudAnalysisService.analyzeOrganization({
      organizationId: pendingOrgId,
      pdfBuffer,
      email: pendingOrg.leaderEmail,
      websiteDomain: undefined,
      originalPdfPath: pendingOrg.certificateUrl,
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

  @Post('reupload-certificate/:pendingOrgId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('certificate'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Re-upload certificate for a pending organization',
    description:
      'Allows admin to manually upload a valid PDF certificate and re-run AI analysis for a pending organization that had an invalid file',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        certificate: {
          type: 'string',
          format: 'binary',
          description: 'Valid PDF certificate document',
        },
      },
      required: ['certificate'],
    },
  })
  @ApiResponse({ status: 200, type: FraudAnalysisResponse })
  async reuploadCertificate(
    @Param('pendingOrgId') pendingOrgId: string,
    @UploadedFile()
    certificate: {
      buffer: Buffer;
      mimetype: string;
      originalname: string;
      size: number;
    },
  ): Promise<FraudAnalysisResponse> {
    if (!certificate) {
      throw new BadRequestException('Certificate file is required');
    }

    // Validate PDF mimetype
    if (certificate.mimetype !== 'application/pdf') {
      throw new BadRequestException(
        `Certificate must be a PDF file (received ${certificate.mimetype})`,
      );
    }

    // Validate PDF magic bytes (file signature)
    const pdfHeader = certificate.buffer.toString('utf8', 0, 5);
    if (!pdfHeader.startsWith('%PDF-')) {
      throw new BadRequestException(
        'Invalid PDF file. The uploaded file does not have a valid PDF header. Please ensure you are uploading a genuine PDF document.',
      );
    }

    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (certificate.size > maxSize) {
      throw new BadRequestException(
        `Certificate PDF file is too large (${(certificate.size / 1024 / 1024).toFixed(2)}MB). Maximum allowed size is 10MB.`,
      );
    }

    // Fetch pending organization
    const pendingOrg =
      await this.pendingOrganizationModel.findById(pendingOrgId);

    if (!pendingOrg) {
      throw new NotFoundException('Pending organization not found');
    }

    console.log('[REUPLOAD] Uploading new certificate for org:', pendingOrgId);

    // Upload new certificate to Cloudinary (replace old one)
    const certificateUrl = await this.cloudinaryService.uploadRawBuffer(
      certificate.buffer,
      {
        folder: 'organization-certificates',
        publicId: `cert_${pendingOrg.requestedBy.toString()}_${Date.now()}`,
        resourceType: 'raw',
      },
    );

    console.log('[REUPLOAD] New certificate uploaded:', certificateUrl);

    // Update pending organization with new certificate URL
    pendingOrg.certificateUrl = certificateUrl;
    await pendingOrg.save();

    // Run AI fraud analysis on the new certificate
    const result = await this.fraudAnalysisService.analyzeOrganization({
      organizationId: pendingOrgId,
      pdfBuffer: certificate.buffer,
      email: pendingOrg.leaderEmail,
      websiteDomain: undefined,
      originalPdfPath: certificateUrl,
    });

    console.log('[REUPLOAD] Fraud analysis completed. Risk:', result.level);

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
