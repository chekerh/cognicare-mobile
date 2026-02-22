/**
 * Shared interfaces for the Excel import system.
 */

/** Represents a single column mapping: Excel header → DB field. */
export interface ColumnMapping {
  /** The normalised header text found in the Excel file. */
  excelHeader: string;
  /** The original header text as-is from the file. */
  originalHeader: string;
  /** The database field this header maps to (null = unmapped). */
  dbField: string | null;
  /** Confidence 0-1 from the auto-suggest engine. */
  confidence: number;
}

/** Payload the frontend sends back after the user confirms/tweaks mappings. */
export interface ConfirmedMapping {
  /** Excel column header (normalised). */
  excelHeader: string;
  /** Target DB field the user chose. */
  dbField: string;
}

/** One row-level error in the import summary. */
export interface ImportRowError {
  row: number;
  field?: string;
  message: string;
}

/** Summary returned after completing an import. */
export interface ImportSummary {
  totalRows: number;
  created: number;
  skipped: number;
  errors: ImportRowError[];
}

/** Extended summary for family+children combined import. */
export interface FamilyChildrenImportSummary extends ImportSummary {
  familiesCreated: number;
  childrenCreated: number;
  childrenSkipped: number;
  childrenErrors: ImportRowError[];
}

/** The target fields each import type exposes. */
export interface FieldDefinition {
  /** Internal DB field name. */
  field: string;
  /** Whether the field is required for a valid row. */
  required: boolean;
  /** Human-readable label. */
  label: string;
}

/** Result from the preview / header-analysis step. */
export interface ImportPreview {
  /** Auto-suggested column mappings. */
  suggestedMappings: ColumnMapping[];
  /** Available DB fields the user can map to. */
  availableFields: FieldDefinition[];
  /** First N data rows for the user to eyeball. */
  sampleRows: Record<string, unknown>[];
  /** Total data rows (excluding header). */
  totalRows: number;
}

export type ImportType =
  | 'staff'
  | 'families'
  | 'children'
  | 'families_children';
