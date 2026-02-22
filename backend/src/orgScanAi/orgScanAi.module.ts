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
import {
  PendingOrganization,
  PendingOrganizationSchema,
} from '../organization/schemas/pending-organization.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: FraudAnalysis.name, schema: FraudAnalysisSchema },
      { name: PendingOrganization.name, schema: PendingOrganizationSchema },
      { name: User.name, schema: UserSchema },
    ]),
    CloudinaryModule,
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
