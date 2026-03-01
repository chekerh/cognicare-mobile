import { Injectable, Logger } from "@nestjs/common";
import axios from "axios";

const FREE_EMAIL_PROVIDERS = new Set([
  "gmail.com",
  "yahoo.com",
  "yahoo.fr",
  "hotmail.com",
  "hotmail.fr",
  "outlook.com",
  "outlook.fr",
  "live.com",
  "aol.com",
  "mail.com",
  "protonmail.com",
  "icloud.com",
  "yandex.com",
  "zoho.com",
  "gmx.com",
  "gmx.fr",
  "orange.fr",
  "free.fr",
  "laposte.net",
  "wanadoo.fr",
  "sfr.fr",
  "bbox.fr",
  "temp-mail.org",
  "guerrillamail.com",
  "mailinator.com",
  "10minutemail.com",
  "throwaway.email",
]);

export interface DomainRiskResult {
  score: number;
  flags: string[];
  isFreeEmail: boolean;
  domainAge?: number;
}

@Injectable()
export class DomainRiskService {
  private readonly logger = new Logger(DomainRiskService.name);

  extractDomain(email: string): string | null {
    if (!email || !email.includes("@")) return null;
    return email.split("@")[1]?.toLowerCase() || null;
  }

  isFreeEmailProvider(domain: string): boolean {
    return FREE_EMAIL_PROVIDERS.has(domain.toLowerCase());
  }

  async checkDomainAge(domain: string): Promise<number | null> {
    try {
      const response = await axios.get<{ creationDate?: string }>(
        `https://whois.freeaiapi.xyz/?name=${domain}`,
        { timeout: 5000 },
      );
      if (response.data?.creationDate) {
        const creationDate = new Date(response.data.creationDate);
        const now = new Date();
        return (
          (now.getFullYear() - creationDate.getFullYear()) * 12 +
          (now.getMonth() - creationDate.getMonth())
        );
      }
      return null;
    } catch {
      this.logger.debug(`Unable to determine domain age for ${domain}`);
      return null;
    }
  }

  async calculateDomainRisk(
    email?: string,
    websiteDomain?: string,
  ): Promise<DomainRiskResult> {
    const flags: string[] = [];
    let score = 0;
    const emailDomain = email ? this.extractDomain(email) : null;

    if (emailDomain && this.isFreeEmailProvider(emailDomain)) {
      score += 0.2;
      flags.push("Free email provider detected");
    }

    const domainToCheck = websiteDomain || emailDomain;
    let domainAge: number | null = null;

    if (domainToCheck && !this.isFreeEmailProvider(domainToCheck)) {
      domainAge = await this.checkDomainAge(domainToCheck);
      if (domainAge !== null && domainAge < 6) {
        score += 0.4;
        flags.push(`Domain younger than 6 months (${domainAge} months)`);
      }
    }

    if (emailDomain && websiteDomain) {
      const normalizedEmail = emailDomain.replace("www.", "");
      const normalizedWebsite = websiteDomain.replace("www.", "").toLowerCase();
      if (
        !this.isFreeEmailProvider(emailDomain) &&
        normalizedEmail !== normalizedWebsite
      ) {
        score += 0.15;
        flags.push("Email domain differs from website domain");
      }
    }

    if (emailDomain) {
      const numericRatio =
        (emailDomain.match(/\d/g) || []).length / emailDomain.length;
      if (numericRatio > 0.3) {
        score += 0.1;
        flags.push("Suspicious domain pattern (numeric-heavy)");
      }
      const domainName = emailDomain.split(".")[0];
      if (domainName && domainName.length < 3) {
        score += 0.1;
        flags.push("Unusually short domain name");
      }
    }

    score = Math.min(score, 1.0);
    this.logger.log(
      `Domain risk analysis: score=${score.toFixed(2)}, flags=[${flags.join(", ")}]`,
    );

    return {
      score,
      flags,
      isFreeEmail: emailDomain ? this.isFreeEmailProvider(emailDomain) : false,
      domainAge: domainAge ?? undefined,
    };
  }
}
