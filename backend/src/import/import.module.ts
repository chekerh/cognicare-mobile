import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ImportController } from './import.controller';
import { ExcelParserService } from './utils';
import {
  StaffImportService,
  FamilyImportService,
  ChildrenImportService,
  FamilyChildrenImportService,
} from './services';
import { User, UserSchema } from '../users/schemas/user.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import {
  Organization,
  OrganizationSchema,
} from '../organization/schemas/organization.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Child.name, schema: ChildSchema },
      { name: Organization.name, schema: OrganizationSchema },
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
