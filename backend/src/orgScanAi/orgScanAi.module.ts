import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { OrgScanAiService } from './orgScanAi.service';
import { OrgScanAiController } from './orgScanAi.controller';
import { SimilarityService } from './similarity.service';
import { RiskService } from './risk.service';
import { DomainRiskService } from './domain-risk.service';
import { FraudAnalysisService } from './fraud-analysis.service';
import {
  FraudAnalysis,
  FraudAnalysisSchema,
} from './schemas/fraud-analysis.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: FraudAnalysis.name, schema: FraudAnalysisSchema },
    ]),
  ],
  controllers: [OrgScanAiController],
  providers: [
    OrgScanAiService,
    SimilarityService,
    RiskService,
    DomainRiskService,
    FraudAnalysisService,
  ],
  exports: [
    OrgScanAiService,
    SimilarityService,
    RiskService,
    DomainRiskService,
    FraudAnalysisService,
  ],
})
export class OrgScanAiModule {}
