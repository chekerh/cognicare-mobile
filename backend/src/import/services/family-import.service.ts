import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from '../../users/schemas/user.schema';
import {
  Organization,
  OrganizationDocument,
} from '../../organization/schemas/organization.schema';
import {
  ImportSummary,
  ImportRowError,
  FieldDefinition,
  ImportPreview,
  ConfirmedMapping,
} from '../interfaces';
import { ExcelParserService, FAMILY_SYNONYMS } from '../utils';

const FAMILY_FIELDS: FieldDefinition[] = [
  { field: 'fullName', required: true, label: 'Full Name' },
  { field: 'email', required: true, label: 'Email' },
  { field: 'phone', required: false, label: 'Phone' },
  { field: 'password', required: false, label: 'Password' },
];

@Injectable()
export class FamilyImportService {
  private readonly logger = new Logger(FamilyImportService.name);

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Organization.name)
    private orgModel: Model<OrganizationDocument>,
    private parser: ExcelParserService,
  ) {}

  async preview(buffer: Buffer): Promise<ImportPreview> {
    const { headers, rows } = await this.parser.parseBuffer(buffer);
    return this.parser.buildPreview(
      headers,
      rows,
      FAMILY_SYNONYMS,
      FAMILY_FIELDS,
    );
  }

  async execute(
    buffer: Buffer,
    orgId: string,
    mappings: ConfirmedMapping[],
    defaultPassword?: string,
  ): Promise<ImportSummary> {
    const { rows } = await this.parser.parseBuffer(buffer);
    const mapped = this.parser.applyMappings(rows, mappings);

    const summary: ImportSummary = {
      totalRows: mapped.length,
      created: 0,
      skipped: 0,
      errors: [],
    };

    const org = await this.orgModel.findById(orgId);
    if (!org) {
      summary.errors.push({
        row: 0,
        message: `Organization ${orgId} not found`,
      });
      return summary;
    }

    for (let i = 0; i < mapped.length; i++) {
      const rowNum = i + 2;
      const row = mapped[i];
      const errors: ImportRowError[] = [];

      const fullName = this.str(row['fullName']);
      const email = this.str(row['email'])?.toLowerCase();

      if (!fullName)
        errors.push({ row: rowNum, field: 'fullName', message: 'Missing' });
      if (!email)
        errors.push({ row: rowNum, field: 'email', message: 'Missing' });

      if (errors.length) {
        summary.errors.push(...errors);
        continue;
      }

      // Duplicate check
      const exists = await this.userModel.findOne({ email });
      if (exists) {
        if (
          !org.familyIds.some((id) => id.toString() === exists._id.toString())
        ) {
          org.familyIds.push(exists._id);
          exists.organizationId = orgId;
          await exists.save();
          await org.save();
        }
        summary.skipped++;
        continue;
      }

      try {
        const password =
          this.str(row['password']) || defaultPassword || 'CogniCare2026!';
        const passwordHash = await bcrypt.hash(password, 12);

        const user = await this.userModel.create({
          fullName,
          email,
          phone: this.str(row['phone']),
          passwordHash,
          role: 'family',
          organizationId: orgId,
        });

        org.familyIds.push(user._id);
        summary.created++;
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Unknown error';
        summary.errors.push({ row: rowNum, message: msg });
      }
    }

    await org.save();
    return summary;
  }

  private str(v: unknown): string | undefined {
    if (v === null || v === undefined) return undefined;
    // eslint-disable-next-line @typescript-eslint/no-base-to-string
    const s = typeof v === 'object' ? JSON.stringify(v) : String(v);
    const trimmed = s.trim();
    return trimmed.length ? trimmed : undefined;
  }
}
