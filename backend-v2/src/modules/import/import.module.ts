import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  UserMongoSchema,
  UserSchema,
} from "@/modules/users/infrastructure/persistence/mongo/user.schema";
import {
  ChildMongoSchema,
  ChildSchema,
} from "@/modules/children/infrastructure/persistence/mongo/child.schema";
import {
  OrganizationMongoSchema,
  OrganizationSchema,
} from "@/modules/organization/infrastructure/persistence/mongo/organization.schema";
import { ImportController } from "./import.controller";
import { ExcelParserService } from "./utils/excel-parser.service";
import { StaffImportService } from "./services/staff-import.service";
import { FamilyImportService } from "./services/family-import.service";
import { ChildrenImportService } from "./services/children-import.service";
import { FamilyChildrenImportService } from "./services/family-children-import.service";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserMongoSchema.name, schema: UserSchema },
      { name: ChildMongoSchema.name, schema: ChildSchema },
      { name: OrganizationMongoSchema.name, schema: OrganizationSchema },
    ]),
  ],
  controllers: [ImportController],
  providers: [
    ExcelParserService,
    StaffImportService,
    FamilyImportService,
    ChildrenImportService,
    FamilyChildrenImportService,
  ],
})
export class ImportModule {}
