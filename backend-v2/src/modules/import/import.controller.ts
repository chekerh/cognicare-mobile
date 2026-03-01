import {
  Controller,
  Post,
  Param,
  UseInterceptors,
  UploadedFile,
  Body,
  BadRequestException,
  UseGuards,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiTags,
  ApiOperation,
  ApiConsumes,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { Roles } from "@/shared/decorators/roles.decorator";
import { RolesGuard } from "@/shared/guards/roles.guard";
import { JwtAuthGuard } from "@/shared/guards/jwt-auth.guard";
import { StaffImportService } from "./services/staff-import.service";
import { FamilyImportService } from "./services/family-import.service";
import { ChildrenImportService } from "./services/children-import.service";
import { FamilyChildrenImportService } from "./services/family-children-import.service";
import { ConfirmImportDto } from "./dto/confirm-import.dto";
import { ImportType } from "./interfaces/import.interfaces";
import {
  STAFF_SYNONYMS,
  FAMILY_SYNONYMS,
  CHILDREN_SYNONYMS,
  FAMILY_CHILDREN_SYNONYMS,
} from "./utils/synonyms";

interface UploadedFileType {
  buffer: Buffer;
  mimetype: string;
  size: number;
  originalname: string;
}

const ALLOWED_MIMETYPES = [
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.ms-excel",
];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

@ApiTags("Import")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("import")
export class ImportController {
  constructor(
    private staffImport: StaffImportService,
    private familyImport: FamilyImportService,
    private childrenImport: ChildrenImportService,
    private familyChildrenImport: FamilyChildrenImportService,
  ) {}

  @Post("preview/:orgId/:type")
  @Roles("admin", "organization_leader")
  @UseInterceptors(FileInterceptor("file"))
  @ApiConsumes("multipart/form-data")
  @ApiOperation({ summary: "Preview Excel import — auto-detect columns" })
  async preview(
    @Param("orgId") orgId: string,
    @Param("type") type: ImportType,
    @UploadedFile() file: UploadedFileType,
  ) {
    this.validateFile(file);
    switch (type) {
      case "staff":
        return this.staffImport.preview(file.buffer);
      case "families":
        return this.familyImport.preview(file.buffer);
      case "children":
        return this.childrenImport.preview(file.buffer);
      case "families_children":
        return this.familyChildrenImport.preview(file.buffer);
      default:
        throw new BadRequestException(`Unknown import type: ${type}`);
    }
  }

  @Post("execute/:orgId/:type")
  @Roles("admin", "organization_leader")
  @UseInterceptors(FileInterceptor("file"))
  @ApiConsumes("multipart/form-data")
  @ApiOperation({
    summary: "Execute Excel import with confirmed column mappings",
  })
  async execute(
    @Param("orgId") orgId: string,
    @Param("type") type: ImportType,
    @UploadedFile() file: UploadedFileType,
    @Body() body: ConfirmImportDto,
  ) {
    this.validateFile(file);
    const mappings = body.mappings;
    switch (type) {
      case "staff":
        return this.staffImport.execute(file.buffer, orgId, mappings);
      case "families":
        return this.familyImport.execute(file.buffer, orgId, mappings);
      case "children":
        return this.childrenImport.execute(file.buffer, orgId, mappings);
      case "families_children":
        return this.familyChildrenImport.execute(file.buffer, orgId, mappings);
      default:
        throw new BadRequestException(`Unknown import type: ${type}`);
    }
  }

  @Post("template/:type")
  @Roles("admin", "organization_leader")
  @ApiOperation({ summary: "Get expected columns for an import type" })
  getTemplate(@Param("type") type: ImportType) {
    switch (type) {
      case "staff":
        return { fields: Object.keys(STAFF_SYNONYMS) };
      case "families":
        return { fields: Object.keys(FAMILY_SYNONYMS) };
      case "children":
        return { fields: Object.keys(CHILDREN_SYNONYMS) };
      case "families_children":
        return { fields: Object.keys(FAMILY_CHILDREN_SYNONYMS) };
      default:
        throw new BadRequestException(`Unknown import type: ${type}`);
    }
  }

  private validateFile(file: UploadedFileType): void {
    if (!file) throw new BadRequestException("No file uploaded");
    if (!ALLOWED_MIMETYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid file type "${file.mimetype}". Allowed: .xlsx, .xls`,
      );
    }
    if (file.size > MAX_SIZE) {
      throw new BadRequestException("File too large. Max 10 MB.");
    }
  }
}
