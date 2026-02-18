import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEmail, IsMongoId } from 'class-validator';

export class AnalyzeOrganizationDto {
  @ApiProperty({ description: 'Organization ID' })
  @IsMongoId()
  organizationId!: string;

  @ApiPropertyOptional({ description: 'Organization email address' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ description: 'Organization website domain' })
  @IsOptional()
  @IsString()
  websiteDomain?: string;
}

export class ReviewAnalysisDto {
  @ApiProperty({ description: 'Reviewer notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class ExtractedFieldsResponse {
  @ApiPropertyOptional()
  name?: string;

  @ApiPropertyOptional()
  registrationNumber?: string;

  @ApiPropertyOptional()
  issuingAuthority?: string;

  @ApiPropertyOptional()
  expirationDate?: string;

  @ApiPropertyOptional()
  address?: string;
}

export class FraudAnalysisResponse {
  @ApiProperty()
  organizationId!: string;

  @ApiProperty()
  analysisId!: string;

  @ApiProperty({ description: 'Fraud risk score (0-1)' })
  fraudRisk!: number;

  @ApiProperty({ enum: ['LOW', 'MEDIUM', 'HIGH'] })
  level!: string;

  @ApiProperty({ type: [String], description: 'Risk flags detected' })
  flags!: string[];

  @ApiProperty({
    description: 'Similarity score to previous submissions (0-1)',
  })
  similarityScore!: number;

  @ApiProperty({ enum: ['LOW', 'MEDIUM', 'HIGH'] })
  similarityRisk!: string;

  @ApiProperty({ type: ExtractedFieldsResponse })
  extractedFields!: ExtractedFieldsResponse;

  @ApiProperty({ description: 'Document inconsistency score (0-1)' })
  documentInconsistencyScore!: number;

  @ApiProperty({ description: 'Domain risk score (0-1)' })
  domainRiskScore!: number;

  @ApiProperty()
  timestamp!: string;
}

export class AnalysisStatsResponse {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  highRisk!: number;

  @ApiProperty()
  mediumRisk!: number;

  @ApiProperty()
  lowRisk!: number;

  @ApiProperty()
  pending!: number;

  @ApiProperty()
  rejected!: number;
}
