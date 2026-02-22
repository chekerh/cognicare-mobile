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

interface OpenAIMessage {
    role: 'system' | 'user' | 'assistant';
    content: string;
}

@Injectable()
export class ChatbotService {
    private readonly logger = new Logger(ChatbotService.name);

    // Provider configs
    private readonly groqApiKey = process.env.GROQ_API_KEY;
    private readonly openaiApiKey = process.env.OPENAI_API_KEY;

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
                ? children.map((c: any) => {
                    const age = c.dateOfBirth
                        ? Math.floor(
                            (Date.now() - new Date(c.dateOfBirth).getTime()) /
                            (1000 * 60 * 60 * 24 * 365),
                        )
                        : null;
                    return `${c.fullName}${age ? ` (${age} ans)` : ''}${c.diagnosis ? `, suivi par ${c.diagnosis}` : ''}`;
                }).join('; ')
                : null;

        // 2. Build system prompt
        const systemPrompt = `Tu es Cogni, l'assistant IA de CogniCare — une application d'accompagnement pour les familles d'enfants avec des besoins spéciaux.
Tu parles à ${userName}.${childrenInfo ? `\nEnfant(s) suivi(s) : ${childrenInfo}.` : ''}
Ton rôle : aider pour les progrès de l'enfant, suggestions thérapeutiques (PECS, TEACCH, activités sensorielles), planification de rappels, routines quotidiennes.
Sois chaleureux, bienveillant et encourageant. Réponds dans la langue de l'utilisateur. Sois concis (2-4 phrases max sauf si demandé). Ne donne jamais de diagnostic médical.`;

        // 3. Build messages array (OpenAI format — 'model' role → 'assistant')
        const messages: OpenAIMessage[] = [
            { role: 'system', content: systemPrompt },
        ];

        // Add history (limit to last 10 exchanges)
        for (const h of history.slice(-10)) {
            messages.push({
                role: h.role === 'model' ? 'assistant' : 'user',
                content: h.content,
            });
        }

        // Add current user message
        messages.push({ role: 'user', content: message });

        // 4. Try Groq first, then OpenAI
        if (this.groqApiKey) {
            try {
                return await this.callOpenAICompatible(
                    'https://api.groq.com/openai/v1/chat/completions',
                    this.groqApiKey,
                    'llama-3.3-70b-versatile',
                    messages,
                );
            } catch (err: any) {
                this.logger.warn(`Groq failed: ${err?.message}. Trying OpenAI...`);
            }
        }

        if (this.openaiApiKey) {
            try {
                return await this.callOpenAICompatible(
                    'https://api.openai.com/v1/chat/completions',
                    this.openaiApiKey,
                    'gpt-4o-mini',
                    messages,
                );
            } catch (err: any) {
                this.logger.error(`OpenAI failed: ${err?.message}`);
                return `Désolé ${userName}, tous les services AI sont temporairement indisponibles. Veuillez réessayer dans quelques instants. 🙏`;
            }
        }

        this.logger.warn('No API keys configured (GROQ_API_KEY, OPENAI_API_KEY)');
        return `${userName}, aucune clé API n'est configurée. Contactez l'administrateur.`;
    }

    private async callOpenAICompatible(
        url: string,
        apiKey: string,
        model: string,
        messages: OpenAIMessage[],
    ): Promise<string> {
        const response = await axios.post(
            url,
            {
                model,
                messages,
                max_tokens: 512,
                temperature: 0.7,
            },
            {
                timeout: 20000,
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`,
                },
            },
        );

        const text: string = response.data?.choices?.[0]?.message?.content ?? '';
        if (!text) throw new Error('Empty response from API');
        return text.trim();
    }
}
