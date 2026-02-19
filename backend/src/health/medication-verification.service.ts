import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class MedicationVerificationService {
    private readonly logger = new Logger(MedicationVerificationService.name);
    private readonly geminiApiKey = process.env.GEMINI_API_KEY;
    private readonly geminiModel = 'gemini-1.5-flash';
    private readonly geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${this.geminiModel}:generateContent`;

    async verifyMedication(imageUrl: string, prescription: any): Promise<any> {
        if (!this.geminiApiKey) {
            throw new Error('Gemini API key not configured');
        }

        const prompt = `
      You are a specialized medical AI assistant for CogniCare, an app for children with autism.
      Your task is to verify if the medication in the provided image matches the child's prescription.

      Prescription: ${JSON.stringify(prescription)}

      Analyze the image for:
      1. Medication name
      2. Dosage (e.g., 10mg, 5ml)
      3. Expiry date
      4. General safety/appropriateness

      Return a JSON object:
      {
        "status": "VALID" | "UNCERTAIN" | "INVALID",
        "reasoning": "Explain your decision clearly for a parent.",
        "metadata": {
          "medicineName": "string",
          "dosage": "string",
          "expiryDate": "string"
        }
      }
    `;

        try {
            // Note: In a real implementation, you would download the image and send it as base64 to Gemini.
            const response = await axios.post(`${this.geminiUrl}?key=${this.geminiApiKey}`, {
                contents: [
                    {
                        parts: [
                            { text: prompt },
                        ],
                    },
                ],
            });

            const resultText = response.data.candidates[0].content.parts[0].text;
            const jsonMatch = resultText.match(/\{[\s\S]*\}/);
            return jsonMatch ? JSON.parse(jsonMatch[0]) : { status: 'UNCERTAIN', reasoning: 'Failed to parse AI response' };
        } catch (error) {
            this.logger.error(`Medication verification failed: ${error.message}`);
            throw error;
        }
    }
}
