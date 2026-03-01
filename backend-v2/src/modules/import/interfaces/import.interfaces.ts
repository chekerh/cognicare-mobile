/**
 * Shared interfaces for the Excel import system.
 */

export interface ColumnMapping {
  excelHeader: string;
  originalHeader: string;
  dbField: string | null;
  confidence: number;
}

export interface ConfirmedMapping {
  excelHeader: string;
  dbField: string;
}

export interface ImportRowError {
  row: number;
  field?: string;
  message: string;
}

export interface ImportSummary {
  totalRows: number;
  created: number;
  skipped: number;
  errors: ImportRowError[];
}

export interface FamilyChildrenImportSummary extends ImportSummary {
  familiesCreated: number;
  childrenCreated: number;
  childrenSkipped: number;
  childrenErrors: ImportRowError[];
}

export interface FieldDefinition {
  field: string;
  required: boolean;
  label: string;
}

export interface ImportPreview {
  suggestedMappings: ColumnMapping[];
  availableFields: FieldDefinition[];
  sampleRows: Record<string, unknown>[];
  totalRows: number;
}

export type ImportType =
  | "staff"
  | "families"
  | "children"
  | "families_children";
