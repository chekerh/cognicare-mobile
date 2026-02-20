import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from '../../users/schemas/user.schema';
import { Child, ChildDocument } from '../../children/schemas/child.schema';
import {
  Organization,
  OrganizationDocument,
} from '../../organization/schemas/organization.schema';
import {
  FamilyChildrenImportSummary,
  ImportRowError,
  FieldDefinition,
  ImportPreview,
  ConfirmedMapping,
} from '../interfaces';
import { ExcelParserService, FAMILY_CHILDREN_SYNONYMS } from '../utils';

const FAMILY_CHILDREN_FIELDS: FieldDefinition[] = [
  // Parent
  { field: 'parentName', required: true, label: 'Parent Name' },
  { field: 'parentEmail', required: true, label: 'Parent Email' },
  { field: 'parentPhone', required: false, label: 'Parent Phone' },
  { field: 'parentPassword', required: false, label: 'Parent Password' },
  // Child
  { field: 'childName', required: true, label: 'Child Name' },
  { field: 'dateOfBirth', required: true, label: 'Date of Birth' },
  { field: 'gender', required: true, label: 'Gender' },
  { field: 'diagnosis', required: false, label: 'Diagnosis' },
  { field: 'medicalHistory', required: false, label: 'Medical History' },
  { field: 'allergies', required: false, label: 'Allergies' },
  { field: 'medications', required: false, label: 'Medications' },
  { field: 'notes', required: false, label: 'Notes' },
];

@Injectable()
export class FamilyChildrenImportService {
  private readonly logger = new Logger(FamilyChildrenImportService.name);

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
      FAMILY_CHILDREN_SYNONYMS,
      FAMILY_CHILDREN_FIELDS,
    );
  }

  /**
   * Combined import: each row has parent info + child info.
   * Multiple rows can share the same parentEmail —
   * the parent is created once, children are attached.
   */
  async execute(
    buffer: Buffer,
    orgId: string,
    mappings: ConfirmedMapping[],
    defaultPassword?: string,
  ): Promise<FamilyChildrenImportSummary> {
    const { rows } = await this.parser.parseBuffer(buffer);
    const mapped = this.parser.applyMappings(rows, mappings);

    const summary: FamilyChildrenImportSummary = {
      totalRows: mapped.length,
      created: 0,
      skipped: 0,
      errors: [],
      familiesCreated: 0,
      childrenCreated: 0,
      childrenSkipped: 0,
      childrenErrors: [],
    };

    const org = await this.orgModel.findById(orgId);
    if (!org) {
      summary.errors.push({
        row: 0,
        message: `Organization ${orgId} not found`,
      });
      return summary;
    }

    // Cache: parentEmail → user doc (created or fetched)
    const parentCache = new Map<string, UserDocument>();

    for (let i = 0; i < mapped.length; i++) {
      const rowNum = i + 2;
      const row = mapped[i];

      // ── Extract parent fields ──
      const parentName = this.str(row['parentName']);
      const parentEmail = this.str(row['parentEmail'])?.toLowerCase();
      const parentPhone = this.str(row['parentPhone']);

      // ── Extract child fields ──
      const childName = this.str(row['childName']);
      const dobRaw = row['dateOfBirth'];
      const genderRaw = this.str(row['gender'])?.toLowerCase();

      // Validate parent
      if (!parentEmail) {
        summary.errors.push({
          row: rowNum,
          field: 'parentEmail',
          message: 'Missing',
        });
        continue;
      }

      // ── Ensure parent exists ──
      let parent = parentCache.get(parentEmail);
      if (!parent) {
        const existing = await this.userModel.findOne({
          email: parentEmail,
        });
        if (existing) {
          parent = existing;
          // Attach to org if not already
          if (
            !org.familyIds.some(
              (id) => id.toString() === existing._id.toString(),
            )
          ) {
            org.familyIds.push(existing._id);
            existing.organizationId = orgId;
            await existing.save();
          }
          summary.skipped++;
        } else {
          if (!parentName) {
            summary.errors.push({
              row: rowNum,
              field: 'parentName',
              message: 'Missing (needed to create parent)',
            });
            continue;
          }
          try {
            const password =
              this.str(row['parentPassword']) ||
              defaultPassword ||
              'CogniCare2026!';
            const passwordHash = await bcrypt.hash(password, 12);
            const newUser = await this.userModel.create({
              fullName: parentName,
              email: parentEmail,
              phone: parentPhone,
              passwordHash,
              role: 'family',
              organizationId: orgId,
            });
            parent = newUser;
            org.familyIds.push(newUser._id);
            summary.familiesCreated++;
            summary.created++;
          } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : 'Unknown error';
            summary.errors.push({ row: rowNum, message: msg });
            continue;
          }
        }
        parentCache.set(parentEmail, parent);
      }

      // ── Now create the child (if child columns present) ──
      if (!childName) {
        // Row only had parent info, no child
        continue;
      }

      const childErrors: ImportRowError[] = [];
      if (!dobRaw)
        childErrors.push({
          row: rowNum,
          field: 'dateOfBirth',
          message: 'Missing',
        });
      if (!genderRaw)
        childErrors.push({
          row: rowNum,
          field: 'gender',
          message: 'Missing',
        });

      if (childErrors.length) {
        summary.childrenErrors.push(...childErrors);
        continue;
      }

      const gender = this.normalizeGender(genderRaw!);
      if (!gender) {
        summary.childrenErrors.push({
          row: rowNum,
          field: 'gender',
          message: `Invalid gender "${genderRaw}"`,
        });
        continue;
      }

      const dateOfBirth = this.parseDate(dobRaw);
      if (!dateOfBirth) {
        summary.childrenErrors.push({
          row: rowNum,
          field: 'dateOfBirth',
          message: `Invalid date "${String(dobRaw)}"`,
        });
        continue;
      }

      // Duplicate child check
      const dupChild = await this.childModel.findOne({
        fullName: childName,
        parentId: parent._id,
        dateOfBirth,
      });
      if (dupChild) {
        summary.childrenSkipped++;
        continue;
      }

      try {
        const child = await this.childModel.create({
          fullName: childName,
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

        summary.childrenCreated++;
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Unknown error';
        summary.childrenErrors.push({ row: rowNum, message: msg });
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
