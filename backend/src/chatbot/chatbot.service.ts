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
        const systemText = `Tu es Cogni, l'assistant IA de CogniCare — app d'accompagnement pour familles d'enfants avec besoins spéciaux.
Tu parles à ${userName}.${childrenInfo ? ` Enfant(s) suivi(s) : ${childrenInfo}.` : ''}
Aide pour : progrès de l'enfant, suggestions thérapeutiques (PECS, TEACCH, sensoriel), rappels, routines, navigation CogniCare.
Sois chaleureux et bienveillant. Réponds dans la langue de l'utilisateur. Sois concis (2-4 phrases). Ne donne jamais de diagnostic médical.`;

        // 3. Build Gemini contents — ENSURING STRICT ALTERNATION
        const geminiContents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

        // System turn (User)
        geminiContents.push({ role: 'user', parts: [{ text: `Instructions système:\n${systemText}` }] });
        // Ack turn (Model)
        geminiContents.push({ role: 'model', parts: [{ text: `Compris ! Je suis Cogni, assistant CogniCare de ${userName}. Comment puis-je vous aider ?` }] });

        // Add history — must start with user and alternate
        const recentHistory = history.slice(-10); // Reduce to avoid overflow
        let lastRole = 'model'; // The one we just added

        for (const h of recentHistory) {
            // Only add if it alternates role
            if (h.role !== lastRole) {
                geminiContents.push({
                    role: h.role,
                    parts: [{ text: h.content }],
                });
                lastRole = h.role;
            }
        }

        // Final turn must be 'user'
        if (lastRole === 'user') {
            // If last msg in history was user, we merge or replace? Let's just append the current message as a new user turn
            // But Gemini doesn't like User -> User.
            // So if last was user, we add a dummy model filler
            geminiContents.push({ role: 'model', parts: [{ text: "Je vous écoute." }] });
        }

        geminiContents.push({
            role: 'user',
            parts: [{ text: message }],
        });

        if (!this.apiKey) {
            this.logger.warn('GEMINI_API_KEY not set');
            return `${userName}, la clé API Gemini n'est pas configurée.`;
        }

        try {
            const response = await axios.post(
                `${this.url}?key=${this.apiKey}`,
                {
                    contents: geminiContents,
                    generationConfig: {
                        maxOutputTokens: 512,
                        temperature: 0.7,
                    },
                },
                {
                    timeout: 20000,
                    headers: { 'Content-Type': 'application/json' },
                },
            );

            const text: string =
                response.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
            if (!text) {
                throw new Error(`Empty response. Reason: ${response.data?.candidates?.[0]?.finishReason}`);
            }
            return text.trim();
        } catch (err: any) {
            const errorData = err.response?.data?.error || err.message;
            this.logger.error(`Gemini Error: ${JSON.stringify(errorData)}`);
            // For debugging: return a snippet of the error to the user UI
            const shortError = JSON.stringify(errorData).substring(0, 100);
            return `Désolé ${userName}, erreur technique : ${shortError}. 🙏`;
        }
    }
}
