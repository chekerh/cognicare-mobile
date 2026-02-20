import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument } from '../../users/schemas/user.schema';
import { Child, ChildDocument } from '../../children/schemas/child.schema';
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
import { ExcelParserService, CHILDREN_SYNONYMS } from '../utils';

const CHILDREN_FIELDS: FieldDefinition[] = [
  { field: 'fullName', required: true, label: 'Child Full Name' },
  { field: 'dateOfBirth', required: true, label: 'Date of Birth' },
  { field: 'gender', required: true, label: 'Gender' },
  { field: 'parentEmail', required: true, label: 'Parent Email' },
  { field: 'diagnosis', required: false, label: 'Diagnosis' },
  { field: 'medicalHistory', required: false, label: 'Medical History' },
  { field: 'allergies', required: false, label: 'Allergies' },
  { field: 'medications', required: false, label: 'Medications' },
  { field: 'notes', required: false, label: 'Notes' },
];

@Injectable()
export class ChildrenImportService {
  private readonly logger = new Logger(ChildrenImportService.name);

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Child.name) private childModel: Model<ChildDocument>,
    @InjectModel(Organization.name)
    private orgModel: Model<OrganizationDocument>,
    private parser: ExcelParserService,
  ) {}

  async preview(buffer: Buffer): Promise<ImportPreview> {
    const { headers, rows } = await this.parser.parseBuffer(buffer);
    return this.parser.buildPreview(
      headers,
      rows,
      CHILDREN_SYNONYMS,
      CHILDREN_FIELDS,
    );
  }

  async execute(
    buffer: Buffer,
    orgId: string,
    mappings: ConfirmedMapping[],
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

    // Pre-load a cache of parent emails → user docs within the org
    const parentCache = new Map<string, UserDocument>();

    for (let i = 0; i < mapped.length; i++) {
      const rowNum = i + 2;
      const row = mapped[i];
      const errors: ImportRowError[] = [];

      const fullName = this.str(row['fullName']);
      const dobRaw = row['dateOfBirth'];
      const genderRaw = this.str(row['gender'])?.toLowerCase();
      const parentEmail = this.str(row['parentEmail'])?.toLowerCase();

      if (!fullName)
        errors.push({ row: rowNum, field: 'fullName', message: 'Missing' });
      if (!dobRaw)
        errors.push({
          row: rowNum,
          field: 'dateOfBirth',
          message: 'Missing',
        });
      if (!genderRaw)
        errors.push({ row: rowNum, field: 'gender', message: 'Missing' });
      if (!parentEmail)
        errors.push({
          row: rowNum,
          field: 'parentEmail',
          message: 'Missing',
        });

      if (errors.length) {
        summary.errors.push(...errors);
        continue;
      }

      // Validate gender
      const gender = this.normalizeGender(genderRaw!);
      if (!gender) {
        summary.errors.push({
          row: rowNum,
          field: 'gender',
          message: `Invalid gender "${genderRaw}"`,
        });
        continue;
      }

      // Parse date
      const dateOfBirth = this.parseDate(dobRaw);
      if (!dateOfBirth) {
        summary.errors.push({
          row: rowNum,
          field: 'dateOfBirth',
          message: `Invalid date "${String(dobRaw)}"`,
        });
        continue;
      }

      // Resolve parent
      let parent = parentCache.get(parentEmail!);
      if (!parent) {
        const found = await this.userModel.findOne({
          email: parentEmail,
          role: 'family',
        });
        if (!found) {
          summary.errors.push({
            row: rowNum,
            field: 'parentEmail',
            message: `Parent not found: "${parentEmail}"`,
          });
          continue;
        }
        parent = found;
        parentCache.set(parentEmail!, found);
      }

      // Duplicate check: same name + same parent + same DOB
      const duplicate = await this.childModel.findOne({
        fullName,
        parentId: parent._id,
        dateOfBirth,
      });
      if (duplicate) {
        summary.skipped++;
        continue;
      }

      try {
        const child = await this.childModel.create({
          fullName,
          dateOfBirth,
          gender,
          diagnosis: this.str(row['diagnosis']),
          medicalHistory: this.str(row['medicalHistory']),
          allergies: this.str(row['allergies']),
          medications: this.str(row['medications']),
          notes: this.str(row['notes']),
          parentId: parent._id,
          organizationId: new Types.ObjectId(orgId),
        });

        if (
          !org.childrenIds.some((id) => id.toString() === child._id.toString())
        ) {
          org.childrenIds.push(child._id);
        }

        summary.created++;
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Unknown error';
        summary.errors.push({ row: rowNum, message: msg });
      }
    }

    await org.save();
    return summary;
  }

  // ─── Helpers ───────────────────────────────

  private str(v: unknown): string | undefined {
    if (v === null || v === undefined) return undefined;
    // eslint-disable-next-line @typescript-eslint/no-base-to-string
    const s = typeof v === 'object' ? JSON.stringify(v) : String(v);
    const trimmed = s.trim();
    return trimmed.length ? trimmed : undefined;
  }

  private normalizeGender(raw: string): string | null {
    const cleaned = raw.toLowerCase().trim();
    const aliases: Record<string, string> = {
      male: 'male',
      m: 'male',
      homme: 'male',
      masculin: 'male',
      ذكر: 'male',
      female: 'female',
      f: 'female',
      femme: 'female',
      feminin: 'female',
      انثى: 'female',
      other: 'other',
      autre: 'other',
      اخر: 'other',
    };
    return aliases[cleaned] ?? null;
  }

  private parseDate(raw: unknown): Date | null {
    if (raw instanceof Date) return raw;
    if (!raw) return null;
    // eslint-disable-next-line @typescript-eslint/no-base-to-string
    const str = typeof raw === 'object' ? JSON.stringify(raw) : String(raw);
    const date = new Date(str.trim());
    if (isNaN(date.getTime())) return null;
    return date;
  }
}
