import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

// List of free/disposable email providers
const FREE_EMAIL_PROVIDERS = new Set([
  'gmail.com',
  'yahoo.com',
  'yahoo.fr',
  'hotmail.com',
  'hotmail.fr',
  'outlook.com',
  'outlook.fr',
  'live.com',
  'aol.com',
  'mail.com',
  'protonmail.com',
  'icloud.com',
  'yandex.com',
  'zoho.com',
  'gmx.com',
  'gmx.fr',
  'orange.fr',
  'free.fr',
  'laposte.net',
  'wanadoo.fr',
  'sfr.fr',
  'bbox.fr',
  'temp-mail.org',
  'guerrillamail.com',
  'mailinator.com',
  '10minutemail.com',
  'throwaway.email',
]);

export interface DomainRiskResult {
  score: number;
  flags: string[];
  isFreeEmail: boolean;
  domainAge?: number; // in months
}

@Injectable()
export class DomainRiskService {
  private readonly logger = new Logger(DomainRiskService.name);

  /**
   * Extract domain from email address
   */
  extractDomain(email: string): string | null {
    if (!email || !email.includes('@')) {
      return null;
    }
    const parts = email.split('@');
    return parts[1]?.toLowerCase() || null;
  }

  /**
   * Check if email is from a free provider
   */
  isFreeEmailProvider(domain: string): boolean {
    return FREE_EMAIL_PROVIDERS.has(domain.toLowerCase());
  }

  /**
   * Check domain age using WHOIS API (simplified check)
   * Returns months since creation or null if unable to determine
   */
  async checkDomainAge(domain: string): Promise<number | null> {
    try {
      // Using a free WHOIS API (limited but works without API key)
      // In production, consider using a proper WHOIS service
      const response = await axios.get<{ creationDate?: string }>(
        `https://whois.freeaiapi.xyz/?name=${domain}`,
        { timeout: 5000 },
      );

      if (response.data?.creationDate) {
        const creationDate = new Date(response.data.creationDate);
        const now = new Date();
        const ageInMonths =
          (now.getFullYear() - creationDate.getFullYear()) * 12 +
          (now.getMonth() - creationDate.getMonth());
        return ageInMonths;
      }

      return null;
    } catch {
      this.logger.debug(`Unable to determine domain age for ${domain}`);
      return null;
    }
  }

  /**
   * Calculate domain risk score and flags
   * @param email - Email address to analyze
   * @param websiteDomain - Optional website domain
   * @returns Risk score (0-1) and associated flags
   */
  async calculateDomainRisk(
    email?: string,
    websiteDomain?: string,
  ): Promise<DomainRiskResult> {
    const flags: string[] = [];
    let score = 0;

    const emailDomain = email ? this.extractDomain(email) : null;

    // Check for free email provider
    if (emailDomain && this.isFreeEmailProvider(emailDomain)) {
      score += 0.2;
      flags.push('Free email provider detected');
    }

    // Check domain age if we have a website domain
    const domainToCheck = websiteDomain || emailDomain;
    let domainAge: number | null = null;

    if (domainToCheck && !this.isFreeEmailProvider(domainToCheck)) {
      domainAge = await this.checkDomainAge(domainToCheck);

      if (domainAge !== null && domainAge < 6) {
        score += 0.4;
        flags.push(`Domain younger than 6 months (${domainAge} months)`);
      }
    }

    // Check for email/website domain mismatch
    if (emailDomain && websiteDomain) {
      const normalizedEmail = emailDomain.replace('www.', '');
      const normalizedWebsite = websiteDomain.replace('www.', '').toLowerCase();

      if (
        !this.isFreeEmailProvider(emailDomain) &&
        normalizedEmail !== normalizedWebsite
      ) {
        score += 0.15;
        flags.push('Email domain differs from website domain');
      }
    }

    // Check for suspicious domain patterns
    if (emailDomain) {
      // Check for numeric-heavy domains (often spam)
      const numericRatio =
        (emailDomain.match(/\d/g) || []).length / emailDomain.length;
      if (numericRatio > 0.3) {
        score += 0.1;
        flags.push('Suspicious domain pattern (numeric-heavy)');
      }

      // Check for very short domain names (often suspicious)
      const domainName = emailDomain.split('.')[0];
      if (domainName && domainName.length < 3) {
        score += 0.1;
        flags.push('Unusually short domain name');
      }
    }

    // Cap score at 1.0
    score = Math.min(score, 1.0);

    this.logger.log(
      `Domain risk analysis: score=${score.toFixed(2)}, flags=[${flags.join(', ')}]`,
    );

    return {
      score,
      flags,
      isFreeEmail: emailDomain ? this.isFreeEmailProvider(emailDomain) : false,
      domainAge: domainAge ?? undefined,
    };
  }
}
