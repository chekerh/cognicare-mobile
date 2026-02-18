import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import pdf from 'pdf-parse';
import * as fs from 'fs';

// Timeout for Gemini requests (30 seconds - compatible with Render free tier)
const GEMINI_TIMEOUT = 30000;

// Gemini API configuration
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
  private readonly geminiModel = 'gemini-1.5-flash';
  private readonly geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${this.geminiModel}:generateContent`;

  /**
   * Extract text content from a PDF file
   * @param filePath - Path to the PDF file
   * @returns Extracted text content
   */
  async extractText(filePath: string): Promise<string> {
    try {
      const dataBuffer = fs.readFileSync(filePath);
      const data = await pdf(dataBuffer);
      this.logger.log(`Successfully extracted text from PDF: ${filePath}`);
      return data.text;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to extract text from PDF: ${message}`);
      throw new Error(`PDF extraction failed: ${message}`);
    }
  }

  /**
   * Extract text from a buffer (useful for uploaded files)
   * @param buffer - PDF file buffer
   * @returns Extracted text content
   */
  async extractTextFromBuffer(buffer: Buffer): Promise<string> {
    try {
      const data = await pdf(buffer);
      this.logger.log('Successfully extracted text from PDF buffer');
      return data.text;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to extract text from buffer: ${message}`);
      throw new Error(`PDF extraction failed: ${message}`);
    }
  }

  /**
   * Analyze document text using Google Gemini AI (gemini-1.5-flash)
   * @param text - Document text to analyze
   * @returns AI analysis result as JSON string
   */
  async analyzeWithAI(text: string): Promise<string> {
    if (!this.geminiApiKey) {
      this.logger.error('GEMINI_API_KEY environment variable is not set');
      throw new Error('Gemini API key not configured');
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
      this.logger.log('Sending document to Gemini for analysis');

      const requestBody: { contents: GeminiContent[] } = {
        contents: [
          {
            parts: [{ text: prompt }],
          },
        ],
      };

      const response = await axios.post<GeminiResponse>(
        `${this.geminiUrl}?key=${this.geminiApiKey}`,
        requestBody,
        {
          timeout: GEMINI_TIMEOUT,
          headers: {
            'Content-Type': 'application/json',
          },
        },
      );

      const aiText =
        response.data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

      if (!aiText) {
        throw new Error('Empty response from Gemini API');
      }

      this.logger.log('Successfully received Gemini AI analysis');
      return aiText;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Gemini AI analysis failed: ${message}`);
      throw new Error(`AI analysis failed: ${message}`);
    }
  }

  /**
   * Calculate fraud risk score based on AI analysis
   * @param aiResult - AI analysis result (string)
   * @returns Risk score between 0 and 1
   */
  calculateRisk(aiResult: string): number {
    let risk = 0;

    const lowerResult = aiResult.toLowerCase();

    if (lowerResult.includes('missing')) {
      risk += 0.3;
      this.logger.warn('Risk factor detected: missing information');
    }
    if (lowerResult.includes('expired')) {
      risk += 0.4;
      this.logger.warn('Risk factor detected: expired document');
    }
    if (lowerResult.includes('inconsistent')) {
      risk += 0.3;
      this.logger.warn('Risk factor detected: inconsistent data');
    }

    // Cap risk at 1.0
    risk = Math.min(risk, 1.0);

    this.logger.log(`Calculated fraud risk score: ${risk}`);
    return risk;
  }

  /**
   * Complete document analysis pipeline
   * @param filePath - Path to PDF document
   * @returns Analysis result with risk score
   */
  async analyzeDocument(
    filePath: string,
  ): Promise<{ analysis: string; riskScore: number }> {
    const text = await this.extractText(filePath);
    const analysis = await this.analyzeWithAI(text);
    const riskScore = this.calculateRisk(analysis);

    return {
      analysis,
      riskScore,
    };
  }

  /**
   * Complete document analysis pipeline from buffer
   * @param buffer - PDF file buffer
   * @returns Analysis result with risk score
   */
  async analyzeDocumentFromBuffer(
    buffer: Buffer,
  ): Promise<{ analysis: string; riskScore: number }> {
    const text = await this.extractTextFromBuffer(buffer);
    const analysis = await this.analyzeWithAI(text);
    const riskScore = this.calculateRisk(analysis);

    return {
      analysis,
      riskScore,
    };
  }

  /**
   * Check if Gemini API is configured and accessible
   * @returns True if Gemini API key is set and API is reachable
   */
  async checkGeminiHealth(): Promise<boolean> {
    if (!this.geminiApiKey) {
      this.logger.error('GEMINI_API_KEY environment variable is not set');
      return false;
    }

    try {
      // Test the API with a minimal request
      const response = await axios.post<GeminiResponse>(
        `${this.geminiUrl}?key=${this.geminiApiKey}`,
        {
          contents: [{ parts: [{ text: 'Hello' }] }],
        },
        {
          timeout: 10000,
          headers: { 'Content-Type': 'application/json' },
        },
      );

      const hasResponse =
        !!response.data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (hasResponse) {
        this.logger.log('Gemini API is healthy and accessible');
        return true;
      }
      return false;
    } catch {
      this.logger.error('Gemini API is not accessible');
      return false;
    }
  }

  /**
   * Check if Gemini API key is configured (without making a request)
   * @returns True if API key is set
   */
  isConfigured(): boolean {
    return !!this.geminiApiKey;
  }
}
