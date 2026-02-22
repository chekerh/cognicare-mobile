import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import axios from 'axios';
import { User, UserDocument } from '../users/schemas/user.schema';
import { Child, ChildDocument } from '../children/schemas/child.schema';
import { TaskReminder, TaskReminderDocument, ReminderType, ReminderFrequency } from '../nutrition/schemas/task-reminder.schema';

export interface ChatMessage {
    role: 'user' | 'model';
    content: string;
}

interface OpenAIMessage {
    role: 'system' | 'user' | 'assistant' | 'tool';
    content: string | null;
    name?: string;
    tool_calls?: any[];
    tool_call_id?: string;
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
        @InjectModel(TaskReminder.name) private readonly taskReminderModel: Model<TaskReminderDocument>,
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
            .select('fullName dateOfBirth diagnosis _id')
            .lean()
            .exec();

        const userName = (user as any)?.fullName ?? 'utilisateur';
        const childrenInfo = children.length > 0
            ? children.map((c: any) => {
                const age = c.dateOfBirth
                    ? Math.floor((Date.now() - new Date(c.dateOfBirth).getTime()) / (1000 * 60 * 60 * 24 * 365))
                    : null;
                return `- ID: ${c._id.toString()}, Nom: ${c.fullName}${age ? ` (${age} ans)` : ''}${c.diagnosis ? `, suivi par ${c.diagnosis}` : ''}`;
            }).join('\n')
            : 'Aucun enfant enregistré.';

        // 2. Build system prompt
        const systemPrompt = `Tu es Cogni, l'assistant IA de CogniCare — une application d'accompagnement pour les familles d'enfants avec des besoins spéciaux.
Tu parles à ${userName}.
Enfants suivis (utilise les ID correspondants pour l'ajout de tâches) :
${childrenInfo}

Ton rôle : aider pour les progrès de l'enfant, suggestions thérapeutiques (PECS, TEACCH, activités sensorielles), planification de rappels, routines quotidiennes.
Si l'utilisateur te demande d'ajouter une tâche ou un rappel, utilise l'outil "add_routine_task" avec le bon "childId". Si l'utilisateur a plusieurs enfants et ne précise pas pour lequel c'est, demande-lui avant d'ajouter.
Sois chaleureux, bienveillant et encourageant. Réponds dans la langue de l'utilisateur. Sois concis (2-4 phrases max sauf si demandé). Ne donne jamais de diagnostic médical.`;

        // 3. Build messages array
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

        // Tool definitions
        const tools = [
            {
                type: "function",
                function: {
                    name: "add_routine_task",
                    description: "Ajoute une nouvelle tâche ou un rappel dans l'agenda quotidien de l'enfant.",
                    parameters: {
                        type: "object",
                        properties: {
                            childId: { type: "string", description: "L'ID de l'enfant (ex: 698f66198ac...). IMPORTANT: doit être un ID valide de la liste." },
                            title: { type: "string", description: "Titre clair de la tâche, ex: 'Faire du sport'" },
                            time: { type: "string", description: "Heure au format HH:mm, ex: '09:30'" }
                        },
                        required: ["childId", "title", "time"]
                    }
                }
            }
        ];

        // 4. Execute AI Call (Multi-turn if tools are used)
        let responseMessage = await this.tryProviders(messages, tools, userName);

        if (responseMessage.tool_calls && responseMessage.tool_calls.length > 0) {
            // Append assistant tool_calls message to history
            messages.push(responseMessage);

            // Execute each tool
            for (const toolCall of responseMessage.tool_calls) {
                if (toolCall.function.name === 'add_routine_task') {
                    try {
                        const args = JSON.parse(toolCall.function.arguments);
                        const result = await this.executeAddRoutineTask(userId, args.childId, args.title, args.time);
                        messages.push({
                            role: 'tool',
                            tool_call_id: toolCall.id,
                            content: result,
                        });
                    } catch (e: any) {
                        this.logger.error(`Tool execution failed: ${e.message}`);
                        messages.push({
                            role: 'tool',
                            tool_call_id: toolCall.id,
                            content: JSON.stringify({ error: e.message }),
                        });
                    }
                }
            }

            // Get final response after tools executed
            responseMessage = await this.tryProviders(messages, tools, userName);
        }

        return responseMessage.content?.trim() || "Je n'ai rien à dire.";
    }

    private async tryProviders(messages: OpenAIMessage[], tools: any[], userName: string): Promise<any> {
        if (this.groqApiKey) {
            try {
                return await this.callOpenAICompatible(
                    'https://api.groq.com/openai/v1/chat/completions',
                    this.groqApiKey,
                    'llama-3.3-70b-versatile',
                    messages,
                    tools
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
                    tools
                );
            } catch (err: any) {
                this.logger.error(`OpenAI failed: ${err?.message}`);
                throw new Error(`Désolé ${userName}, tous les services AI sont temporairement indisponibles.`);
            }
        }

        throw new Error(`${userName}, aucune clé API n'est configurée.`);
    }

    private async callOpenAICompatible(
        url: string,
        apiKey: string,
        model: string,
        messages: OpenAIMessage[],
        tools: any[]
    ): Promise<any> {
        const response = await axios.post(
            url,
            {
                model,
                messages,
                tools,
                tool_choice: 'auto',
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

        const messageData = response.data?.choices?.[0]?.message;
        if (!messageData) throw new Error('Empty response from API');
        return messageData;
    }

    private async executeAddRoutineTask(userId: string, childId: string, title: string, time: string): Promise<string> {
        try {
            // Verify child belongs to user
            const childExists = await this.childModel.findOne({ _id: childId, parentId: userId }).lean().exec();
            if (!childExists) {
                return JSON.stringify({ success: false, error: "L'enfant spécifié n'a pas été trouvé ou n'appartient pas à l'utilisateur." });
            }

            const newTask = new this.taskReminderModel({
                childId: new Types.ObjectId(childId),
                createdBy: new Types.ObjectId(userId),
                type: ReminderType.CUSTOM,
                title: title,
                frequency: ReminderFrequency.ONCE,
                times: [time],
                icon: "📅",
                color: "#A7DBE6", // primary color
                soundEnabled: true,
                vibrationEnabled: true,
                isActive: true,
            });

            await newTask.save();
            return JSON.stringify({ success: true, message: `Tâche '${title}' ajoutée à ${time} pour ${childExists.fullName}.` });
        } catch (error: any) {
            this.logger.error(`Database Error inserting task: ${error.message}`);
            return JSON.stringify({ success: false, error: error.message });
        }
    }
}
