import { Injectable, Logger } from '@nestjs/common';

export interface ExtractedFields {
  name?: string;
  registrationNumber?: string;
  issuingAuthority?: string;
  expirationDate?: string;
  address?: string;
}

export interface FraudRiskResult {
  fraudRisk: number;
  level: 'LOW' | 'MEDIUM' | 'HIGH';
  flags: string[];
  documentInconsistencyScore: number;
  similarityScore: number;
  domainRiskScore: number;
}

@Injectable()
export class RiskService {
  private readonly logger = new Logger(RiskService.name);

  // Weights for fraud risk calculation
  private readonly DOCUMENT_WEIGHT = 0.4;
  private readonly SIMILARITY_WEIGHT = 0.3;
  private readonly DOMAIN_WEIGHT = 0.3;

  /**
   * Calculate document inconsistency score from AI analysis
   * @param aiResponse - Raw AI response string
   * @param extractedFields - Extracted document fields
   * @returns Inconsistency score between 0 and 1
   */
  calculateDocumentInconsistency(
    aiResponse: string,
    extractedFields: ExtractedFields,
  ): { score: number; flags: string[] } {
    const flags: string[] = [];
    let score = 0;
    const lowerResponse = aiResponse.toLowerCase();

    // Check for missing fields
    const requiredFields: (keyof ExtractedFields)[] = [
      'name',
      'registrationNumber',
      'issuingAuthority',
      'expirationDate',
    ];

    for (const field of requiredFields) {
      if (!extractedFields[field] || extractedFields[field] === '') {
        score += 0.15;
        flags.push(`Missing field: ${field}`);
      }
    }

    // Check for keywords indicating issues
    if (lowerResponse.includes('missing')) {
      score += 0.15;
      flags.push('AI detected missing information');
    }

    if (lowerResponse.includes('expired')) {
      score += 0.25;
      flags.push('Expired document detected');
    }

    if (lowerResponse.includes('inconsistent')) {
      score += 0.2;
      flags.push('Inconsistent data detected');
    }

    if (lowerResponse.includes('suspicious')) {
      score += 0.2;
      flags.push('Suspicious elements detected');
    }

    if (lowerResponse.includes('invalid')) {
      score += 0.2;
      flags.push('Invalid information detected');
    }

    if (lowerResponse.includes('mismatch')) {
      score += 0.15;
      flags.push('Information mismatch detected');
    }

    if (lowerResponse.includes('forged') || lowerResponse.includes('fake')) {
      score += 0.4;
      flags.push('Potential forgery indicators');
    }

    // Check expiration date
    if (extractedFields.expirationDate) {
      try {
        const expDate = new Date(extractedFields.expirationDate);
        const now = new Date();

        if (expDate < now) {
          score += 0.3;
          flags.push('Document has expired');
        } else {
          const monthsUntilExpiry =
            (expDate.getFullYear() - now.getFullYear()) * 12 +
            (expDate.getMonth() - now.getMonth());

          if (monthsUntilExpiry < 3) {
            score += 0.1;
            flags.push('Document expiring soon (< 3 months)');
          }
        }
      } catch {
        // Invalid date format
        score += 0.1;
        flags.push('Unable to parse expiration date');
      }
    }

    // Cap score at 1.0
    score = Math.min(score, 1.0);

    return { score, flags };
  }

  /**
   * Calculate final fraud risk using weighted formula
   * @param documentScore - Document inconsistency score (0-1)
   * @param similarityScore - Document similarity score (0-1)
   * @param domainScore - Domain risk score (0-1)
   * @param additionalFlags - Additional flags from other services
   * @returns Complete fraud risk result
   */
  calculateFraudRisk(
    documentScore: number,
    similarityScore: number,
    domainScore: number,
    additionalFlags: string[] = [],
  ): FraudRiskResult {
    // Apply weighted formula
    const fraudRisk =
      documentScore * this.DOCUMENT_WEIGHT +
      similarityScore * this.SIMILARITY_WEIGHT +
      domainScore * this.DOMAIN_WEIGHT;

    // Determine risk level
    let level: 'LOW' | 'MEDIUM' | 'HIGH';
    if (fraudRisk >= 0.6) {
      level = 'HIGH';
    } else if (fraudRisk >= 0.3) {
      level = 'MEDIUM';
    } else {
      level = 'LOW';
    }

    // Generate summary flags
    const flags: string[] = [...additionalFlags];

    if (documentScore > 0.5) {
      flags.push('High document inconsistency');
    }
    if (similarityScore > 0.85) {
      flags.push('High similarity to previous submission');
    }
    if (domainScore > 0.3) {
      flags.push('Domain risk factors detected');
    }

    this.logger.log(
      `Fraud risk calculated: ${(fraudRisk * 100).toFixed(1)}% (${level})`,
    );
    this.logger.log(
      `Components: doc=${(documentScore * 100).toFixed(1)}%, sim=${(similarityScore * 100).toFixed(1)}%, domain=${(domainScore * 100).toFixed(1)}%`,
    );

    return {
      fraudRisk: Math.min(fraudRisk, 1.0),
      level,
      flags,
      documentInconsistencyScore: documentScore,
      similarityScore,
      domainRiskScore: domainScore,
    };
  }

  /**
   * Parse AI response to extract structured fields
   * @param aiResponse - Raw AI response (should be JSON)
   * @returns Extracted fields object
   */
  parseExtractedFields(aiResponse: string): ExtractedFields {
    try {
      // Try to find JSON in the response
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);

        return {
          name:
            parsed.organization_name ||
            parsed.organizationName ||
            parsed.name ||
            undefined,
          registrationNumber:
            parsed.registration_number ||
            parsed.registrationNumber ||
            undefined,
          issuingAuthority:
            parsed.issuing_authority || parsed.issuingAuthority || undefined,
          expirationDate:
            parsed.expiration_date || parsed.expirationDate || undefined,
          address: parsed.address || undefined,
        };
      }
    } catch {
      this.logger.warn('Failed to parse AI response as JSON');
    }

    return {};
  }

  /**
   * Get risk level from score
   */
  getRiskLevel(score: number): 'LOW' | 'MEDIUM' | 'HIGH' {
    if (score >= 0.6) return 'HIGH';
    if (score >= 0.3) return 'MEDIUM';
    return 'LOW';
  }
}
