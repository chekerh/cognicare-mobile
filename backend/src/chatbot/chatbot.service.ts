import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import axios from 'axios';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';

export interface ChatMessage {
    role: 'user' | 'model';
    content: string;
}

@Injectable()
export class ChatbotService {
    private readonly logger = new Logger(ChatbotService.name);
    private readonly apiKey = process.env.GEMINI_API_KEY;
    private readonly model = 'gemini-1.5-flash';
    private readonly url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent`;

    constructor(
        @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
        @InjectModel(Child.name) private readonly childModel: Model<ChildDocument>,
    ) { }

    async chat(
        userId: string,
        message: string,
        history: ChatMessage[],
    ): Promise<string> {
        // 1. Fetch user context
        const user = await this.userModel
            .findById(userId)
            .select('fullName role')
            .lean()
            .exec();
        const children = await this.childModel
            .find({ parentId: userId })
            .select('fullName dateOfBirth diagnosis')
            .lean()
            .exec();

        const userName = (user as any)?.fullName ?? 'utilisateur';
        const childrenInfo =
            children.length > 0
                ? children
                    .map((c: any) => {
                        const age = c.dateOfBirth
                            ? Math.floor(
                                (Date.now() - new Date(c.dateOfBirth).getTime()) /
                                (1000 * 60 * 60 * 24 * 365),
                            )
                            : null;
                        return `${c.fullName}${age ? ` (${age} ans)` : ''}${c.diagnosis ? `, suivi par ${c.diagnosis}` : ''}`;
                    })
                    .join('; ')
                : null;

        // 2. Build system prompt
        const systemPrompt = `Tu es Cogni, l'assistant IA de l'application CogniCare — une app d'accompagnement pour les familles d'enfants avec des besoins spéciaux.
Tu parles à ${userName}.
${childrenInfo ? `Enfant(s) suivi(s) : ${childrenInfo}.` : ''}

Ton rôle est d'aider l'utilisateur à :
- Consulter les progrès et tâches de l'enfant
- Obtenir des suggestions thérapeutiques adaptées (PECS, TEACCH, activités sensorielles...)
- Planifier des rappels et tâches quotidiennes
- Naviguer dans l'app CogniCare
- Répondre à des questions sur la prise en charge de l'enfant

Sois chaleureux, encourageant et bienveillant. Réponds toujours dans la langue de l'utilisateur (français ou arabe si l'utilisateur écrit en arabe). Sois concis (maximum 3-4 phrases sauf si l'utilisateur demande plus de détails). Ne donne jamais de diagnostic médical.`;

        // 3. Build Gemini conversation history
        const geminiContents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

        // Add history (limit to last 10 exchanges)
        const recentHistory = history.slice(-20);
        for (const h of recentHistory) {
            geminiContents.push({
                role: h.role,
                parts: [{ text: h.content }],
            });
        }

        // Add current user message
        geminiContents.push({
            role: 'user',
            parts: [{ text: message }],
        });

        if (!this.apiKey) {
            this.logger.warn('GEMINI_API_KEY not set; returning placeholder');
            return `Bonjour ${userName} ! Je suis Cogni, votre assistant CogniCare. La clé API Gemini n'est pas configurée. Contactez l'administrateur.`;
        }

        try {
            const response = await axios.post(
                `${this.url}?key=${this.apiKey}`,
                {
                    system_instruction: {
                        parts: [{ text: systemPrompt }],
                    },
                    contents: geminiContents,
                    generationConfig: {
                        maxOutputTokens: 512,
                        temperature: 0.7,
                    },
                },
                {
                    timeout: 30000,
                    headers: { 'Content-Type': 'application/json' },
                },
            );

            const text: string =
                response.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
            if (!text) throw new Error('Empty response from Gemini');
            return text.trim();
        } catch (err: any) {
            this.logger.error(`Chatbot Gemini call failed: ${err?.message ?? err}`);
            return `Désolé ${userName}, je rencontre une difficulté technique. Veuillez réessayer dans quelques instants. 🙏`;
        }
    }
}
