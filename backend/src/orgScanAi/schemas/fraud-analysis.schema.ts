import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type FraudAnalysisDocument = FraudAnalysis & Document;

@Schema({ timestamps: true })
export class ExtractedFields {
  @Prop()
  name?: string;

  @Prop()
  registrationNumber?: string;

  @Prop()
  issuingAuthority?: string;

  @Prop()
  expirationDate?: string;

  @Prop()
  address?: string;
}

@Schema({ timestamps: true })
export class FraudAnalysis {
  @Prop({ type: Types.ObjectId, ref: 'Organization', required: true })
  organizationId!: Types.ObjectId;

  @Prop({ type: ExtractedFields })
  extractedFields!: ExtractedFields;

  @Prop({ required: true })
  aiRawResponse!: string;

  @Prop({ required: true, min: 0, max: 1 })
  fraudRiskScore!: number;

  @Prop({ required: true, enum: ['LOW', 'MEDIUM', 'HIGH'] })
  fraudRiskLevel!: string;

  @Prop({ min: 0, max: 1, default: 0 })
  similarityScore!: number;

  @Prop({ enum: ['LOW', 'MEDIUM', 'HIGH'], default: 'LOW' })
  similarityRisk!: string;

  @Prop({ min: 0, max: 1, default: 0 })
  documentInconsistencyScore!: number;

  @Prop({ min: 0, max: 1, default: 0 })
  domainRiskScore!: number;

  @Prop({ type: [String], default: [] })
  flags!: string[];

  @Prop()
  originalPdfPath?: string;

  @Prop()
  emailDomain?: string;

  @Prop()
  websiteDomain?: string;

  @Prop({ type: [Number], default: [] })
  embedding!: number[];

  @Prop({ default: false })
  isRejected!: boolean;

  @Prop()
  reviewedAt?: Date;

  @Prop()
  reviewedBy?: string;

  @Prop()
  reviewNotes?: string;
}

export const FraudAnalysisSchema = SchemaFactory.createForClass(FraudAnalysis);

// Index for efficient similarity searches
FraudAnalysisSchema.index({ organizationId: 1 });
FraudAnalysisSchema.index({ fraudRiskLevel: 1 });
FraudAnalysisSchema.index({ createdAt: -1 });
