import { Injectable, Logger } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import * as bcrypt from "bcryptjs";
import {
  UserMongoSchema,
  UserDocument,
} from "@/modules/users/infrastructure/persistence/mongo/user.schema";
import {
  ChildMongoSchema,
  ChildDocument,
} from "@/modules/children/infrastructure/persistence/mongo/child.schema";
import {
  OrganizationMongoSchema,
  OrganizationDocument,
} from "@/modules/organization/infrastructure/persistence/mongo/organization.schema";
import {
  FamilyChildrenImportSummary,
  ImportRowError,
  FieldDefinition,
  ImportPreview,
  ConfirmedMapping,
} from "../interfaces/import.interfaces";
import { ExcelParserService } from "../utils/excel-parser.service";
import { FAMILY_CHILDREN_SYNONYMS } from "../utils/synonyms";

const FAMILY_CHILDREN_FIELDS: FieldDefinition[] = [
  { field: "parentName", required: true, label: "Parent Name" },
  { field: "parentEmail", required: true, label: "Parent Email" },
  { field: "parentPhone", required: false, label: "Parent Phone" },
  { field: "parentPassword", required: false, label: "Parent Password" },
  { field: "childName", required: true, label: "Child Name" },
  { field: "dateOfBirth", required: true, label: "Date of Birth" },
  { field: "gender", required: true, label: "Gender" },
  { field: "diagnosis", required: false, label: "Diagnosis" },
  { field: "medicalHistory", required: false, label: "Medical History" },
  { field: "allergies", required: false, label: "Allergies" },
  { field: "medications", required: false, label: "Medications" },
  { field: "notes", required: false, label: "Notes" },
];

const DEFAULT_PASSWORD = "CogniCare2024!";

@Injectable()
export class FamilyChildrenImportService {
  private readonly logger = new Logger(FamilyChildrenImportService.name);

  constructor(
    @InjectModel(UserMongoSchema.name) private userModel: Model<UserDocument>,
    @InjectModel(ChildMongoSchema.name)
    private childModel: Model<ChildDocument>,
    @InjectModel(OrganizationMongoSchema.name)
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

  async execute(
    buffer: Buffer,
    orgId: string,
    mappings: ConfirmedMapping[],
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

    const parentCache = new Map<string, UserDocument>();

    for (let i = 0; i < mapped.length; i++) {
      const rowNum = i + 2;
      const row = mapped[i];
      const errors: ImportRowError[] = [];

      const parentName = this.str(row["parentName"]);
      const parentEmail = this.str(row["parentEmail"])?.toLowerCase();
      const parentPhone = this.str(row["parentPhone"]);
      const parentPassword =
        this.str(row["parentPassword"]) || DEFAULT_PASSWORD;
      const childName = this.str(row["childName"]);
      const dobRaw = row["dateOfBirth"];
      const genderRaw = this.str(row["gender"])?.toLowerCase();

      if (!parentName)
        errors.push({ row: rowNum, field: "parentName", message: "Missing" });
      if (!parentEmail)
        errors.push({ row: rowNum, field: "parentEmail", message: "Missing" });
      if (!childName)
        errors.push({ row: rowNum, field: "childName", message: "Missing" });
      if (!dobRaw)
        errors.push({ row: rowNum, field: "dateOfBirth", message: "Missing" });
      if (!genderRaw)
        errors.push({ row: rowNum, field: "gender", message: "Missing" });

      if (errors.length) {
        summary.errors.push(...errors);
        summary.childrenErrors.push(...errors);
        continue;
      }

      const gender = this.normalizeGender(genderRaw!);
      if (!gender) {
        const err = {
          row: rowNum,
          field: "gender",
          message: `Invalid gender "${genderRaw}"`,
        };
        summary.errors.push(err);
        summary.childrenErrors.push(err);
        continue;
      }

      const dateOfBirth = this.parseDate(dobRaw);
      if (!dateOfBirth) {
        const err = {
          row: rowNum,
          field: "dateOfBirth",
          message: `Invalid date "${String(dobRaw)}"`,
        };
        summary.errors.push(err);
        summary.childrenErrors.push(err);
        continue;
      }

      // Get or create parent
      let parent = parentCache.get(parentEmail!);
      if (!parent) {
        const existing = await this.userModel.findOne({ email: parentEmail });
        if (existing) {
          parent = existing;
        } else {
          try {
            const hash = await bcrypt.hash(parentPassword, 12);
            parent = await this.userModel.create({
              fullName: parentName,
              email: parentEmail,
              password: hash,
              phone: parentPhone,
              role: "family",
              isEmailVerified: true,
              organizationId: new Types.ObjectId(orgId),
            });
            summary.familiesCreated++;

            if (
              !org.staffIds?.some(
                (id: any) => id.toString() === parent!._id.toString(),
              )
            ) {
              if (!(org as any).staffIds) (org as any).staffIds = [];
              (org as any).staffIds.push(parent._id);
            }
          } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : "Unknown error";
            summary.errors.push({
              row: rowNum,
              message: `Failed to create parent: ${msg}`,
            });
            continue;
          }
        }
        parentCache.set(parentEmail!, parent);
      }

      // Check duplicate child
      const duplicate = await this.childModel.findOne({
        fullName: childName,
        parentId: parent._id,
        dateOfBirth,
      });
      if (duplicate) {
        summary.childrenSkipped++;
        summary.skipped++;
        continue;
      }

      try {
        const child = await this.childModel.create({
          fullName: childName,
          dateOfBirth,
          gender,
          diagnosis: this.str(row["diagnosis"]),
          medicalHistory: this.str(row["medicalHistory"]),
          allergies: this.str(row["allergies"]),
          medications: this.str(row["medications"]),
          notes: this.str(row["notes"]),
          parentId: parent._id,
          organizationId: new Types.ObjectId(orgId),
        });

        if (
          !org.childIds?.some(
            (id: any) => id.toString() === child._id.toString(),
          )
        ) {
          if (!org.childIds) (org as any).childIds = [];
          org.childIds.push(child._id);
        }

        summary.childrenCreated++;
        summary.created++;
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : "Unknown error";
        const rowErr = { row: rowNum, message: msg };
        summary.errors.push(rowErr);
        summary.childrenErrors.push(rowErr);
      }
    }

    await org.save();
    return summary;
  }

  private str(v: unknown): string | undefined {
    if (v === null || v === undefined) return undefined;
    const s = typeof v === "object" ? JSON.stringify(v) : String(v);
    const trimmed = s.trim();
    return trimmed.length ? trimmed : undefined;
  }

  private normalizeGender(raw: string): string | null {
    const cleaned = raw.toLowerCase().trim();
    const aliases: Record<string, string> = {
      male: "male",
      m: "male",
      homme: "male",
      masculin: "male",
      ذكر: "male",
      female: "female",
      f: "female",
      femme: "female",
      feminin: "female",
      انثى: "female",
      other: "other",
      autre: "other",
      اخر: "other",
    };
    return aliases[cleaned] ?? null;
  }

  private parseDate(raw: unknown): Date | null {
    if (raw instanceof Date) return raw;
    if (!raw) return null;
    const str = typeof raw === "object" ? JSON.stringify(raw) : String(raw);
    const date = new Date(str.trim());
    if (isNaN(date.getTime())) return null;
    return date;
  }
}
