import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import { ColumnMapping, FieldDefinition, ImportPreview } from '../interfaces';
import { SynonymDictionary } from './synonyms';

@Injectable()
export class ExcelParserService {
  // ─── Public API ───────────────────────────────

  /**
   * Parse an uploaded Excel buffer and return raw data rows
   * keyed by **normalised** header text.
   */
  async parseBuffer(
    buffer: Buffer,
  ): Promise<{ headers: string[]; rows: Record<string, unknown>[] }> {
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as unknown as ArrayBuffer);
    const sheet = workbook.worksheets[0];
    if (!sheet) throw new Error('Excel file has no worksheets');

    const headerRow = sheet.getRow(1);
    const headers: string[] = [];
    headerRow.eachCell({ includeEmpty: false }, (cell, colNumber) => {
      headers[colNumber] = this.normalise(
        this.cellToString(cell) || `Column ${colNumber}`,
      );
    });

    const originalHeaders: string[] = [];
    headerRow.eachCell({ includeEmpty: false }, (cell, colNumber) => {
      originalHeaders[colNumber] = (this.cellToString(cell) || '').trim();
    });

    const rows: Record<string, unknown>[] = [];
    sheet.eachRow({ includeEmpty: false }, (row, rowNumber) => {
      if (rowNumber === 1) return; // skip header
      const record: Record<string, unknown> = {};
      row.eachCell({ includeEmpty: true }, (_cell, colNumber) => {
        const header = headers[colNumber];
        if (header) {
          record[header] = this.getCellValue(_cell);
        }
      });
      // Skip completely empty rows
      if (Object.values(record).some((v) => v !== null && v !== '')) {
        rows.push(record);
      }
    });

    // de-dup and compact
    const uniqueHeaders = headers.filter(Boolean);
    return { headers: uniqueHeaders, rows };
  }

  /**
   * Build an ImportPreview from a parsed file + synonym dictionary.
   */
  buildPreview(
    headers: string[],
    rows: Record<string, unknown>[],
    synonyms: SynonymDictionary,
    fields: FieldDefinition[],
    sampleSize = 5,
  ): ImportPreview {
    const suggestedMappings = this.suggestMappings(headers, synonyms);
    return {
      suggestedMappings,
      availableFields: fields,
      sampleRows: rows.slice(0, sampleSize),
      totalRows: rows.length,
    };
  }

  /**
   * Apply confirmed mappings to raw rows → produce objects keyed
   * by DB field names.
   */
  applyMappings(
    rows: Record<string, unknown>[],
    mappings: { excelHeader: string; dbField: string }[],
  ): Record<string, unknown>[] {
    const map = new Map(
      mappings.map((m) => [this.normalise(m.excelHeader), m.dbField]),
    );
    return rows.map((row) => {
      const mapped: Record<string, unknown> = {};
      for (const [header, value] of Object.entries(row)) {
        const field = map.get(this.normalise(header));
        if (field) mapped[field] = value;
      }
      return mapped;
    });
  }

  // ─── Header matching ─────────────────────────

  suggestMappings(
    headers: string[],
    synonyms: SynonymDictionary,
  ): ColumnMapping[] {
    return headers.map((header) => {
      const best = this.findBestMatch(header, synonyms);
      return {
        excelHeader: header,
        originalHeader: header,
        dbField: best.field,
        confidence: best.confidence,
      };
    });
  }

  private findBestMatch(
    header: string,
    synonyms: SynonymDictionary,
  ): { field: string | null; confidence: number } {
    const normHeader = this.normalise(header);
    let bestField: string | null = null;
    let bestScore = 0;

    for (const [field, syns] of Object.entries(synonyms)) {
      for (const syn of syns) {
        const normSyn = this.normalise(syn);
        const score = this.similarity(normHeader, normSyn);
        if (score > bestScore) {
          bestScore = score;
          bestField = field;
        }
      }
    }

    // Minimum confidence threshold
    if (bestScore < 0.4) return { field: null, confidence: 0 };
    return { field: bestField, confidence: bestScore };
  }

  // ─── Utilities ────────────────────────────────

  /**
   * Normalise a header string: trim, lower-case, strip diacritics,
   * collapse whitespace, remove common punctuation.
   */
  normalise(text: string): string {
    return text
      .trim()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // strip diacritics
      .replace(/[_\-./\\]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Simple similarity score between two normalised strings.
   * Exact match = 1, contains = 0.8, word overlap = 0.6, etc.
   */
  private similarity(a: string, b: string): number {
    if (a === b) return 1;
    if (a.includes(b) || b.includes(a)) return 0.85;
    // Word overlap
    const wordsA = new Set(a.split(' '));
    const wordsB = new Set(b.split(' '));
    const intersection = [...wordsA].filter((w) => wordsB.has(w));
    const union = new Set([...wordsA, ...wordsB]);
    const jaccard = intersection.length / union.size;
    return jaccard * 0.8; // cap word-overlap at 0.8
  }

  /**
   * Safely extract a cell value, handling dates, formulas, etc.
   */
  private getCellValue(cell: ExcelJS.Cell): unknown {
    if (cell.value === null || cell.value === undefined) return null;
    if (cell.type === ExcelJS.ValueType.Date) return cell.value;
    if (cell.type === ExcelJS.ValueType.Formula) {
      return (cell.value as ExcelJS.CellFormulaValue).result ?? null;
    }
    if (cell.type === ExcelJS.ValueType.RichText) {
      return (cell.value as ExcelJS.CellRichTextValue).richText
        .map((rt) => rt.text)
        .join('');
    }
    return this.cellToString(cell) || null;
  }

  /**
   * Convert cell value to a plain string, safely handling all ExcelJS types.
   */
  private cellToString(cell: ExcelJS.Cell): string {
    if (cell.value === null || cell.value === undefined) return '';
    if (typeof cell.value === 'string') return cell.value;
    if (typeof cell.value === 'number' || typeof cell.value === 'boolean') {
      return String(cell.value);
    }
    if (cell.value instanceof Date) return cell.value.toISOString();
    if (cell.type === ExcelJS.ValueType.RichText) {
      return (cell.value as ExcelJS.CellRichTextValue).richText
        .map((rt) => rt.text)
        .join('');
    }
    if (cell.type === ExcelJS.ValueType.Formula) {
      const result = (cell.value as ExcelJS.CellFormulaValue).result;
      if (result == null) return '';
      if (typeof result === 'string') return result;
      if (typeof result === 'number' || typeof result === 'boolean')
        return String(result);
      if (result instanceof Date) return result.toISOString();
      return '';
    }
    return cell.text ?? '';
  }
}
