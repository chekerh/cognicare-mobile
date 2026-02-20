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
import { ExcelParserService, STAFF_SYNONYMS } from '../utils';

const STAFF_ROLES = [
  'doctor',
  'volunteer',
  'psychologist',
  'speech_therapist',
  'occupational_therapist',
  'other',
] as const;

/** DB fields available for staff import. */
const STAFF_FIELDS: FieldDefinition[] = [
  { field: 'fullName', required: true, label: 'Full Name' },
  { field: 'email', required: true, label: 'Email' },
  { field: 'phone', required: false, label: 'Phone' },
  { field: 'role', required: true, label: 'Role' },
  { field: 'password', required: false, label: 'Password' },
];

@Injectable()
export class StaffImportService {
  private readonly logger = new Logger(StaffImportService.name);

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Organization.name)
    private orgModel: Model<OrganizationDocument>,
    private parser: ExcelParserService,
  ) {}

  /** Step 1 – Parse file & return preview with auto-suggested mappings. */
  async preview(buffer: Buffer): Promise<ImportPreview> {
    const { headers, rows } = await this.parser.parseBuffer(buffer);
    return this.parser.buildPreview(
      headers,
      rows,
      STAFF_SYNONYMS,
      STAFF_FIELDS,
    );
  }

  /** Step 2 – Execute import with confirmed mappings. */
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
      const rowNum = i + 2; // Excel row (1-indexed header + offset)
      const row = mapped[i];
      const errors: ImportRowError[] = [];

      // ── Validate required fields ──
      const fullName = this.str(row['fullName']);
      const email = this.str(row['email'])?.toLowerCase();
      const roleRaw = this.str(row['role'])?.toLowerCase();

      if (!fullName)
        errors.push({ row: rowNum, field: 'fullName', message: 'Missing' });
      if (!email)
        errors.push({ row: rowNum, field: 'email', message: 'Missing' });
      if (!roleRaw)
        errors.push({ row: rowNum, field: 'role', message: 'Missing' });

      if (errors.length) {
        summary.errors.push(...errors);
        continue;
      }

      // ── Normalize role ──
      const role = this.normalizeRole(roleRaw!);
      if (!role) {
        summary.errors.push({
          row: rowNum,
          field: 'role',
          message: `Invalid role "${roleRaw}"`,
        });
        continue;
      }

      // ── Duplicate check ──
      const exists = await this.userModel.findOne({ email });
      if (exists) {
        // If user already exists, just attach to org if not already
        if (
          !org.staffIds.some((id) => id.toString() === exists._id.toString())
        ) {
          org.staffIds.push(exists._id);
          exists.organizationId = orgId;
          await exists.save();
          await org.save();
        }
        summary.skipped++;
        continue;
      }

      // ── Create user ──
      try {
        const password =
          this.str(row['password']) || defaultPassword || 'CogniCare2026!';
        const passwordHash = await bcrypt.hash(password, 12);

        const user = await this.userModel.create({
          fullName,
          email,
          phone: this.str(row['phone']),
          passwordHash,
          role,
          organizationId: orgId,
        });

        org.staffIds.push(user._id);
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

  private normalizeRole(raw: string): string | null {
    const cleaned = raw
      .toLowerCase()
      .replace(/[_\-\s]+/g, '_')
      .trim();
    const aliases: Record<string, string> = {
      doctor: 'doctor',
      dr: 'doctor',
      medecin: 'doctor',
      طبيب: 'doctor',
      volunteer: 'volunteer',
      benevole: 'volunteer',
      متطوع: 'volunteer',
      psychologist: 'psychologist',
      psychologue: 'psychologist',
      اخصائي_نفسي: 'psychologist',
      speech_therapist: 'speech_therapist',
      orthophoniste: 'speech_therapist',
      اخصائي_نطق: 'speech_therapist',
      occupational_therapist: 'occupational_therapist',
      ergotherapeute: 'occupational_therapist',
      معالج_وظيفي: 'occupational_therapist',
      other: 'other',
      autre: 'other',
      اخرى: 'other',
    };

    if (aliases[cleaned]) return aliases[cleaned];
    if ((STAFF_ROLES as readonly string[]).includes(cleaned)) return cleaned;
    return null;
  }
}
