import { Injectable, Logger } from "@nestjs/common";
import axios from "axios";

type PDFParseFunction = (
  buffer: Buffer,
) => Promise<{ text: string; numpages: number; info: any }>;

const GEMINI_TIMEOUT = 30000;

interface GeminiContent {
  parts: Array<{ text: string }>;
}

interface GeminiResponse {
  candidates: Array<{
    content: {
      parts: Array<{ text: string }>;
    };
  }>;
}

@Injectable()
export class OrgScanAiService {
  private readonly logger = new Logger(OrgScanAiService.name);
  private readonly geminiApiKey = process.env.GEMINI_API_KEY;
  private readonly geminiModel = "gemini-2.0-flash";
  private readonly geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${this.geminiModel}:generateContent`;

  private async getPdfParse(): Promise<PDFParseFunction> {
    const module = await import("pdf-parse");
    return (module as any).default || module;
  }

  async extractTextFromBuffer(buffer: Buffer): Promise<string> {
    try {
      this.logger.log(
        `Extracting text from PDF buffer (${buffer.length} bytes)`,
      );
      const pdfParse = await this.getPdfParse();
      const data = await pdfParse(buffer);
      this.logger.log(
        `Successfully extracted ${data.text.length} characters from PDF`,
      );
      return data.text;
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.error(`Failed to extract text from buffer: ${message}`);
      throw new Error(`PDF extraction failed: ${message}`);
    }
  }

  async analyzeWithAI(text: string): Promise<string> {
    if (!this.geminiApiKey) {
      this.logger.error("GEMINI_API_KEY environment variable is not set");
      throw new Error("Gemini API key not configured");
    }

    const prompt = `You are analyzing a document from a medical care organization for children with autism.

Extract the following information and detect any suspicious elements:

Required fields to extract:
- organization_name: The name of the organization
- registration_number: Official registration/license number
- issuing_authority: Government body that issued the license
- expiration_date: When the license/certificate expires (format: YYYY-MM-DD if found)
- address: Physical address of the organization

Also analyze for:
- Missing or incomplete information
- Expired licenses or certificates
- Inconsistent data (e.g., mismatched names, invalid numbers)
- Signs of document manipulation
- Suspicious patterns

Return ONLY a valid JSON object in this exact format:
{
  "organization_name": "string or null",
  "registration_number": "string or null",
  "issuing_authority": "string or null",
  "expiration_date": "string or null",
  "address": "string or null",
  "issues_found": ["list of issues detected"],
  "suspicious_elements": ["list of suspicious patterns"],
  "overall_assessment": "valid|suspicious|invalid"
}

Document text:
${text.slice(0, 8000)}
`;

    try {
      this.logger.log("Sending document to Gemini for analysis");

      const requestBody: { contents: GeminiContent[] } = {
        contents: [{ parts: [{ text: prompt }] }],
      };

      const response = await axios.post<GeminiResponse>(
        `${this.geminiUrl}?key=${this.geminiApiKey}`,
        requestBody,
        {
          timeout: GEMINI_TIMEOUT,
          headers: { "Content-Type": "application/json" },
        },
      );

      const aiText =
        response.data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      if (!aiText) throw new Error("Empty response from Gemini API");

      this.logger.log("Successfully received Gemini AI analysis");
      return aiText;
    } catch (error) {
      if (axios.isAxiosError(error) && error.response) {
        const status = error.response.status;
        const errorData = error.response.data;
        if (status === 429) throw new Error("AI analysis quota exceeded.");
        if (status === 401 || status === 403)
          throw new Error("AI analysis authentication failed.");
        throw new Error(
          `AI analysis failed: ${errorData?.error?.message || "API error"}`,
        );
      }
      const message = error instanceof Error ? error.message : "Unknown error";
      throw new Error(`AI analysis failed: ${message}`);
    }
  }

  calculateRisk(aiResult: string): number {
    let risk = 0;
    const lowerResult = aiResult.toLowerCase();
    if (lowerResult.includes("missing")) risk += 0.3;
    if (lowerResult.includes("expired")) risk += 0.4;
    if (lowerResult.includes("inconsistent")) risk += 0.3;
    return Math.min(risk, 1.0);
  }

  async analyzeDocumentFromBuffer(
    buffer: Buffer,
  ): Promise<{ analysis: string; riskScore: number }> {
    const text = await this.extractTextFromBuffer(buffer);
    const analysis = await this.analyzeWithAI(text);
    const riskScore = this.calculateRisk(analysis);
    return { analysis, riskScore };
  }

  async checkGeminiHealth(): Promise<boolean> {
    if (!this.geminiApiKey) return false;
    try {
      const response = await axios.post<GeminiResponse>(
        `${this.geminiUrl}?key=${this.geminiApiKey}`,
        { contents: [{ parts: [{ text: "Hello" }] }] },
        { timeout: 10000, headers: { "Content-Type": "application/json" } },
      );
      return !!response.data.candidates?.[0]?.content?.parts?.[0]?.text;
    } catch {
      this.logger.error("Gemini API health check failed");
      return false;
    }
  }

  isConfigured(): boolean {
    return !!this.geminiApiKey;
  }
}
