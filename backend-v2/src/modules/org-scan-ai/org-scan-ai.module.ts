import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { OrgScanAiController } from "./org-scan-ai.controller";
import { OrgScanAiService } from "./org-scan-ai.service";
import { FraudAnalysisService } from "./fraud-analysis.service";
import { SimilarityService } from "./similarity.service";
import { RiskService } from "./risk.service";
import { DomainRiskService } from "./domain-risk.service";
import {
  FraudAnalysis,
  FraudAnalysisSchema,
} from "./schemas/fraud-analysis.schema";
import {
  PendingOrganization,
  PendingOrganizationSchema,
} from "@/modules/organization/infrastructure/persistence/mongo/pending-organization.schema";
import {
  UserMongoSchema,
  UserSchema,
} from "@/modules/users/infrastructure/persistence/mongo/user.schema";
import { CloudinaryModule } from "@/modules/cloudinary/cloudinary.module";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: FraudAnalysis.name, schema: FraudAnalysisSchema },
      { name: PendingOrganization.name, schema: PendingOrganizationSchema },
      { name: UserMongoSchema.name, schema: UserSchema },
    ]),
    CloudinaryModule,
  ],
  controllers: [OrgScanAiController],
  providers: [
    OrgScanAiService,
    FraudAnalysisService,
    SimilarityService,
    RiskService,
    DomainRiskService,
  ],
  exports: [
    OrgScanAiService,
    FraudAnalysisService,
    SimilarityService,
    RiskService,
    DomainRiskService,
  ],
})
export class OrgScanAiModule {}
