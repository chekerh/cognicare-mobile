import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Param,
  BadRequestException,
  Query,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

/** Minimal multer file type to avoid @types/multer dependency issues. */
interface UploadedFileType {
  buffer: Buffer;
  mimetype: string;
  size: number;
  originalname: string;
}
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ConfirmImportDto } from './dto';
import {
  StaffImportService,
  FamilyImportService,
  ChildrenImportService,
  FamilyChildrenImportService,
} from './services';

/**
 * Import controller: two-step flow per import type.
 *
 * Step 1 — POST /import/preview/:orgId/:type
 *   Upload Excel → get auto-suggested mappings + sample rows.
 *
 * Step 2 — POST /import/execute/:orgId/:type
 *   Upload same Excel + confirmed mappings → run import.
 */
@ApiTags('import')
@ApiBearerAuth()
@Controller('import')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ImportController {
  constructor(
    private readonly staffImport: StaffImportService,
    private readonly familyImport: FamilyImportService,
    private readonly childrenImport: ChildrenImportService,
    private readonly familyChildrenImport: FamilyChildrenImportService,
  ) {}

  // ──────────────────────────────────────────────
  // PREVIEW (Step 1)
  // ──────────────────────────────────────────────
  @Post('preview/:orgId/:type')
  @Roles('admin', 'organization_leader')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload Excel and get column mapping suggestions',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  async preview(
    @Param('orgId') orgId: string,
    @Param('type') type: string,
    @UploadedFile() file: UploadedFileType,
  ) {
    this.validateFile(file);
    const buffer = Buffer.from(file.buffer);

    switch (type) {
      case 'staff':
        return this.staffImport.preview(buffer);
      case 'families':
        return this.familyImport.preview(buffer);
      case 'children':
        return this.childrenImport.preview(buffer);
      case 'families_children':
        return this.familyChildrenImport.preview(buffer);
      default:
        throw new BadRequestException(
          `Invalid import type "${type}". ` +
            'Use: staff, families, children, families_children',
        );
    }
  }

  // ──────────────────────────────────────────────
  // EXECUTE (Step 2)
  // ──────────────────────────────────────────────
  @Post('execute/:orgId/:type')
  @Roles('admin', 'organization_leader')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Execute import with confirmed column mappings',
  })
  async execute(
    @Param('orgId') orgId: string,
    @Param('type') type: string,
    @UploadedFile() file: UploadedFileType,
    @Body() body: ConfirmImportDto,
    @Query('defaultPassword') defaultPassword?: string,
  ) {
    this.validateFile(file);
    const buffer = Buffer.from(file.buffer);
    const { mappings } = body;

    switch (type) {
      case 'staff':
        return this.staffImport.execute(
          buffer,
          orgId,
          mappings,
          defaultPassword,
        );
      case 'families':
        return this.familyImport.execute(
          buffer,
          orgId,
          mappings,
          defaultPassword,
        );
      case 'children':
        return this.childrenImport.execute(buffer, orgId, mappings);
      case 'families_children':
        return this.familyChildrenImport.execute(
          buffer,
          orgId,
          mappings,
          defaultPassword,
        );
      default:
        throw new BadRequestException(
          `Invalid import type "${type}". ` +
            'Use: staff, families, children, families_children',
        );
    }
  }

  // ──────────────────────────────────────────────
  // TEMPLATE DOWNLOAD (bonus)
  // ──────────────────────────────────────────────
  @Post('template/:type')
  @Roles('admin', 'organization_leader')
  @ApiOperation({ summary: 'Get expected columns for an import type' })
  getTemplate(@Param('type') type: string) {
    const templates: Record<string, string[]> = {
      staff: ['Full Name', 'Email', 'Phone', 'Role', 'Password'],
      families: ['Full Name', 'Email', 'Phone', 'Password'],
      children: [
        'Child Name',
        'Date of Birth',
        'Gender',
        'Parent Email',
        'Diagnosis',
        'Medical History',
        'Allergies',
        'Medications',
        'Notes',
      ],
      families_children: [
        'Parent Name',
        'Parent Email',
        'Parent Phone',
        'Parent Password',
        'Child Name',
        'Date of Birth',
        'Gender',
        'Diagnosis',
        'Medical History',
        'Allergies',
        'Medications',
        'Notes',
      ],
    };

    const cols = templates[type];
    if (!cols) {
      throw new BadRequestException(
        `Invalid import type "${type}". ` +
          'Use: staff, families, children, families_children',
      );
    }

    return { importType: type, columns: cols };
  }

  // ──────────────────────────────────────────────
  private validateFile(file: UploadedFileType): void {
    if (!file) throw new BadRequestException('No file uploaded');

    const allowed = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
    ];
    if (!allowed.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Upload an Excel file (.xlsx / .xls)',
      );
    }

    const maxSize = 10 * 1024 * 1024; // 10 MB
    if (file.size > maxSize) {
      throw new BadRequestException('File too large. Maximum size is 10 MB');
    }
  }
}
