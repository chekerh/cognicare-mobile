import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import * as fs from 'fs';
import { join } from 'path';

@Injectable()
export class MedicationVerificationService {
  private readonly logger = new Logger(MedicationVerificationService.name);
  private readonly groqApiKey = process.env.GROQ_API_KEY;
  private readonly openFdaApiKey = process.env.OPEN_FDA_API_KEY;
  private readonly groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  private readonly groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  async verifyMedication(imagePath: string, prescription: any): Promise<any> {
    if (!this.groqApiKey) throw new Error('Groq API key not configured (GROQ_API_KEY)');

    const todayStr = new Date().toLocaleDateString('fr-FR', { year: 'numeric', month: '2-digit', day: '2-digit' });

    const prompt = `Tu es un assistant médical bienveillant pour des parents d'enfants autistes.
Aujourd'hui: ${todayStr}.
Examine l'image, identifie nom/dosage/péremption, compare avec l'ordonnance.
**Ordonnance:** ${JSON.stringify(prescription)}
Réponds UNIQUEMENT avec un JSON valide:
{"status":"VALID"|"UNCERTAIN"|"INVALID","reasoning":"message simple","metadata":{"medicineName":"...","dosage":"...","expiryDate":"...","isExpired":true|false|null,"manufacturer":"...","detailedDescription":"..."}}`;

    try {
      const cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
      let fullPath = join(process.cwd(), cleanPath);
      if (!fs.existsSync(fullPath)) fullPath = join(process.cwd(), 'backend', cleanPath);
      if (!fs.existsSync(fullPath)) {
        return { status: 'UNCERTAIN', reasoning: 'Fichier image introuvable.', metadata: { medicineName: 'N/A', dosage: 'N/A', expiryDate: 'N/A', isExpired: null } };
      }

      const imageBuffer = fs.readFileSync(fullPath);
      const base64Image = imageBuffer.toString('base64');
      const mimeType = this.detectMimeType(imageBuffer, imagePath);

      const groqResponse = await axios.post(this.groqUrl, {
        model: this.groqModel,
        messages: [{ role: 'user', content: [{ type: 'text', text: prompt }, { type: 'image_url', image_url: { url: `data:${mimeType};base64,${base64Image}` } }] }],
        temperature: 0.1, max_tokens: 1024,
      }, { timeout: 30000, headers: { Authorization: `Bearer ${this.groqApiKey}`, 'Content-Type': 'application/json' } });

      const resultText = (groqResponse.data as { choices: Array<{ message: { content: string } }> }).choices[0].message.content;
      let aiResult: any;
      try {
        const cleaned = resultText.replace(/```json\n?/gi, '').replace(/```\n?/gi, '').trim();
        const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
        aiResult = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
      } catch { aiResult = null; }

      if (!aiResult) return { status: 'UNCERTAIN', reasoning: "Réponse IA non interprétée.", metadata: { medicineName: 'N/A', dosage: 'N/A', expiryDate: 'N/A', isExpired: null } };
      if (!aiResult.metadata) aiResult.metadata = {};

      if (aiResult.metadata.expiryDate && !['N/A', 'Non visible'].includes(aiResult.metadata.expiryDate)) {
        const expired = this.checkExpiryDate(aiResult.metadata.expiryDate);
        if (expired !== null) {
          aiResult.metadata.isExpired = expired;
          if (expired) {
            aiResult.status = 'INVALID';
            aiResult.reasoning = `⚠️ STOP ! Ce médicament est PÉRIMÉ. Ne le donnez PAS.`;
          }
        }
      }

      if (aiResult.metadata?.medicineName && aiResult.metadata.medicineName !== 'N/A') {
        const fdaInfo = await this.validateWithFDA(aiResult.metadata.medicineName);
        if (fdaInfo) aiResult.metadata.fda_generic_name = (fdaInfo as any).openfda?.generic_name?.[0];
      }

      return aiResult;
    } catch (error: any) {
      this.logger.error(`Vérification échouée: ${error.message}`);
      throw error;
    }
  }

  private detectMimeType(buffer: Buffer, fallbackPath: string): string {
    if (buffer[0] === 0x89 && buffer[1] === 0x50) return 'image/png';
    if (buffer[0] === 0xff && buffer[1] === 0xd8) return 'image/jpeg';
    if (buffer[0] === 0x47 && buffer[1] === 0x49) return 'image/gif';
    if (buffer[0] === 0x52 && buffer[1] === 0x49) return 'image/webp';
    return fallbackPath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  }

  private checkExpiryDate(dateStr: string): boolean | null {
    try {
      const now = new Date();
      const m1 = dateStr.match(/(\d{1,2})[\/\-](\d{2,4})/);
      if (m1) { let y = parseInt(m1[2], 10); if (y < 100) y += 2000; return new Date(y, parseInt(m1[1], 10), 0) < now; }
      const m2 = dateStr.match(/(\d{4})[\/\-](\d{1,2})/);
      if (m2) return new Date(parseInt(m2[1], 10), parseInt(m2[2], 10), 0) < now;
      return null;
    } catch { return null; }
  }

  private async validateWithFDA(drugName: string): Promise<any> {
    const suffix = this.openFdaApiKey ? `&api_key=${this.openFdaApiKey}` : '';
    try {
      const r = await axios.get<{ results?: unknown[] }>(`https://api.fda.gov/drug/label.json?search=openfda.brand_name:"${encodeURIComponent(drugName)}"&limit=1${suffix}`, { timeout: 5000 });
      if (r.data.results?.length) return r.data.results[0];
    } catch {
      try {
        const r = await axios.get<{ results?: unknown[] }>(`https://api.fda.gov/drug/label.json?search=openfda.generic_name:"${encodeURIComponent(drugName)}"&limit=1${suffix}`, { timeout: 5000 });
        if (r.data.results?.length) return r.data.results[0];
      } catch { return null; }
    }
    return null;
  }
}
