import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import * as fs from 'fs';
import { join } from 'path';

@Injectable()
export class MedicationVerificationService {
  private readonly logger = new Logger(MedicationVerificationService.name);
  private readonly groqApiKey = process.env.GROQ_API_KEY;
  private readonly openFdaApiKey = process.env.OPEN_FDA_API_KEY;
  // Groq vision model — free tier: 30 req/min, 1000 req/day
  private readonly groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  private readonly groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  async verifyMedication(imagePath: string, prescription: any): Promise<any> {
    if (!this.groqApiKey) {
      throw new Error('Groq API key not configured (GROQ_API_KEY)');
    }

    const today = new Date();
    const todayStr = today.toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });

    const prompt = `Tu es un assistant médical bienveillant pour des parents d'enfants autistes.
Aujourd'hui, nous sommes le ${todayStr}.

Ta mission :
1. Examine l'image du médicament.
2. Identifie le nom, le dosage et la date de péremption.
3. Compare avec l'ordonnance fournie.
4. Détermine si c'est le bon médicament et s'il est sûr à utiliser (non périmé).

**Ordonnance :** ${JSON.stringify(prescription)}

**Instructions pour ton retour (très important) :**
- Ton explication dans "reasoning" doit être TRÈS SIMPLE et RASSURANTE pour un parent si tout est OK.
- Ne parle pas de "status VALID", de "code OCR" ou de détails techniques.
- SI TOUT EST CORRECT : Dis "C'est parfait, c'est bien le [Nom] demandé. Vous pouvez le donner en toute sécurité."
- SI LE MÉDICAMENT EST INCORRECT OU PÉRIMÉ : Dis clairement : "Attention, ce n'est pas le bon médicament/dosage" ou "Désolé, ce médicament est périmé, ne l'utilisez pas."
- Dans "metadata.detailedDescription", explique brièvement les principaux composants actifs de ce médicament et ses effets sur le corps de l'enfant (texte éducatif).
- Utilise un ton empathique et clair.

**IMPORTANT : Réponds UNIQUEMENT avec un objet JSON valide :**
{
  "status": "VALID" | "UNCERTAIN" | "INVALID",
  "reasoning": "Ton message simple et bienveillant pour le parent.",
  "metadata": {
    "medicineName": "Nom trouvé (ex: Doliprane 500mg)",
    "dosage": "Dosage (ex: 500mg)",
    "expiryDate": "Date lue ou 'Non visible'",
    "isExpired": true | false | null,
    "manufacturer": "Marque si visible",
    "detailedDescription": "Explication éducative des composants et effets."
  }
}`;

    try {
      this.logger.log(`Démarrage vérification AI (Groq) pour: ${imagePath}`);

      // 1. Lire l'image et la convertir en base64
      const cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;
      let fullPath = join(process.cwd(), cleanPath);
      this.logger.log(`Chemin testé: ${fullPath}`);

      if (!fs.existsSync(fullPath)) {
        fullPath = join(process.cwd(), 'backend', cleanPath);
        this.logger.log(`Chemin alternatif: ${fullPath}`);
      }

      if (!fs.existsSync(fullPath)) {
        this.logger.error(`Image introuvable: ${imagePath}`);
        return {
          status: 'UNCERTAIN',
          reasoning:
            'Fichier image introuvable sur le serveur. Veuillez reprendre la photo.',
          metadata: {
            medicineName: 'N/A',
            dosage: 'N/A',
            expiryDate: 'N/A',
            isExpired: null,
          },
        };
      }

      const imageBuffer = fs.readFileSync(fullPath);
      const base64Image = imageBuffer.toString('base64');
      const mimeType = this.detectMimeType(imageBuffer, imagePath);
      this.logger.log(
        `Image chargée: ${mimeType} (${imageBuffer.length} octets). Envoi à Groq...`,
      );

      // 2. Appel Groq API (format OpenAI-compatible avec vision)
      const groqResponse = await axios.post(
        this.groqUrl,
        {
          model: this.groqModel,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: prompt,
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:${mimeType};base64,${base64Image}`,
                  },
                },
              ],
            },
          ],
          temperature: 0.1,
          max_tokens: 1024,
        },
        {
          timeout: 30000,
          headers: {
            Authorization: `Bearer ${this.groqApiKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      const resultText = groqResponse.data.choices[0].message.content;
      this.logger.log(`Réponse Groq: ${resultText}`);

      // 3. Parse the JSON response robustly
      let aiResult: any;
      try {
        const cleaned = resultText
          .replace(/```json\n?/gi, '')
          .replace(/```\n?/gi, '')
          .trim();
        const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
        aiResult = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
      } catch (parseErr) {
        this.logger.warn(
          `Erreur de parsing JSON: ${parseErr.message}. Texte: ${resultText}`,
        );
        aiResult = null;
      }

      if (!aiResult) {
        return {
          status: 'UNCERTAIN',
          reasoning:
            "La réponse de l'IA n'a pas pu être interprétée. Veuillez réessayer avec une photo plus nette.",
          metadata: {
            medicineName: 'N/A',
            dosage: 'N/A',
            expiryDate: 'N/A',
            isExpired: null,
          },
        };
      }

      // 4. Ensure metadata exists
      if (!aiResult.metadata) {
        aiResult.metadata = {};
      }

      // 5. Vérification logic de la date d'expiration (Safety Net)
      if (
        aiResult.metadata.expiryDate &&
        aiResult.metadata.expiryDate !== 'N/A' &&
        aiResult.metadata.expiryDate !== 'Non visible'
      ) {
        const expiredCheck = this.checkExpiryDate(aiResult.metadata.expiryDate);
        if (expiredCheck !== null) {
          aiResult.metadata.isExpired = expiredCheck;
          if (expiredCheck) {
            aiResult.status = 'INVALID';
            // On remplace totalement pour éviter "Périmé. C'est parfait vous pouvez le donner"
            aiResult.reasoning = `⚠️ STOP ! Ce médicament (${aiResult.metadata.medicineName}) est PÉRIMÉ depuis le ${aiResult.metadata.expiryDate}. Ne le donnez PAS à votre enfant. Jetez-le et utilisez une boîte neuve.`;
          }
        }
      }

      // 6. Validation optionnelle FDA (pour les médicaments américains)
      if (
        aiResult.metadata?.medicineName &&
        aiResult.metadata.medicineName !== 'N/A'
      ) {
        const fdaInfo = await this.validateWithFDA(
          aiResult.metadata.medicineName,
        );
        if (fdaInfo) {
          this.logger.log(
            `Validation FDA réussie pour: ${aiResult.metadata.medicineName}`,
          );
          aiResult.metadata.fda_generic_name =
            fdaInfo.openfda?.generic_name?.[0];
        } else {
          this.logger.warn(
            `Médicament non trouvé dans la FDA (normal pour les médicaments français): ${aiResult.metadata.medicineName}`,
          );
        }
      }

      this.logger.log(`Résultat final Groq: ${JSON.stringify(aiResult)}`);
      return aiResult;
    } catch (error) {
      if (error.response) {
        this.logger.error(
          `Groq API Error: ${JSON.stringify(error.response?.data)}`,
        );
      }
      this.logger.error(`Vérification échouée: ${error.message}`);
      throw error;
    }
  }

  /**
   * Detect MIME type from file magic bytes for accuracy.
   */
  private detectMimeType(buffer: Buffer, fallbackPath: string): string {
    if (
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4e &&
      buffer[3] === 0x47
    ) {
      return 'image/png';
    }
    if (buffer[0] === 0xff && buffer[1] === 0xd8) {
      return 'image/jpeg';
    }
    if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
      return 'image/gif';
    }
    if (
      buffer[0] === 0x52 &&
      buffer[1] === 0x49 &&
      buffer[2] === 0x46 &&
      buffer[3] === 0x46
    ) {
      return 'image/webp';
    }
    return fallbackPath.toLowerCase().endsWith('.png')
      ? 'image/png'
      : 'image/jpeg';
  }

  /**
   * Check if a medication is expired given a date string.
   * Returns true if expired, false if valid, null if unparseable.
   */
  private checkExpiryDate(dateStr: string): boolean | null {
    try {
      const now = new Date();
      const match1 = dateStr.match(/(\d{1,2})[\/\-](\d{2,4})/);
      if (match1) {
        const month = parseInt(match1[1], 10);
        let year = parseInt(match1[2], 10);
        if (year < 100) year += 2000;
        const expiry = new Date(year, month, 0);
        return expiry < now;
      }
      const match2 = dateStr.match(/(\d{4})[\/\-](\d{1,2})/);
      if (match2) {
        const year = parseInt(match2[1], 10);
        const month = parseInt(match2[2], 10);
        const expiry = new Date(year, month, 0);
        return expiry < now;
      }
      return null;
    } catch {
      return null;
    }
  }

  private async validateWithFDA(drugName: string): Promise<any> {
    const apiKeySuffix = this.openFdaApiKey
      ? `&api_key=${this.openFdaApiKey}`
      : '';
    try {
      const brandUrl = `https://api.fda.gov/drug/label.json?search=openfda.brand_name:"${encodeURIComponent(drugName)}"&limit=1${apiKeySuffix}`;
      const brandResponse = await axios.get(brandUrl, { timeout: 5000 });
      if (brandResponse.data.results?.length > 0) {
        return brandResponse.data.results[0];
      }
    } catch (_e) {
      try {
        const genericUrl = `https://api.fda.gov/drug/label.json?search=openfda.generic_name:"${encodeURIComponent(drugName)}"&limit=1${apiKeySuffix}`;
        const genericResponse = await axios.get(genericUrl, { timeout: 5000 });
        if (genericResponse.data.results?.length > 0) {
          return genericResponse.data.results[0];
        }
      } catch {
        return null;
      }
    }
    return null;
  }
}
