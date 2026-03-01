import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import axios from 'axios';

export interface ChatMessage { role: 'user' | 'model'; content: string; }

interface OpenAIMessage { role: 'system' | 'user' | 'assistant' | 'tool'; content: string | null; name?: string; tool_calls?: any[]; tool_call_id?: string; }

@Injectable()
export class ChatbotService {
  private readonly logger = new Logger(ChatbotService.name);
  private readonly groqApiKey = process.env.GROQ_API_KEY;
  private readonly openaiApiKey = process.env.OPENAI_API_KEY;

  constructor(
    @InjectModel('User') private readonly userModel: Model<any>,
    @InjectModel('Child') private readonly childModel: Model<any>,
    @InjectModel('TaskReminder') private readonly taskReminderModel: Model<any>,
  ) {}

  async chat(userId: string, message: string, history: ChatMessage[]): Promise<string> {
    const user = await this.userModel.findById(userId).select('fullName role').lean().exec();
    const children = await this.childModel.find({ parentId: new Types.ObjectId(userId) }).select('fullName dateOfBirth diagnosis').lean().exec();

    const userName = (user as any)?.fullName ?? 'utilisateur';
    const childrenInfo = children.length > 0
      ? children.map((c: any) => {
          const age = c.dateOfBirth ? Math.floor((Date.now() - new Date(c.dateOfBirth).getTime()) / (1000 * 60 * 60 * 24 * 365)) : null;
          return `- ID: ${c._id?.toString()}, Nom: ${c.fullName}${age ? ` (${age} ans)` : ''}${c.diagnosis ? `, suivi par ${c.diagnosis}` : ''}`;
        }).join('\n')
      : 'Aucun enfant enregistré.';

    const systemPrompt = `Tu es Cogni, l'assistant IA de CogniCare — une application d'accompagnement pour les familles d'enfants avec des besoins spéciaux.
Tu parles à ${userName}.
Enfants suivis:\n${childrenInfo}
Ton rôle : aider pour les progrès de l'enfant, suggestions thérapeutiques, planification de rappels.
Si l'utilisateur demande d'ajouter une tâche, utilise l'outil "add_routine_task".
Sois chaleureux et concis (2-4 phrases). Ne donne jamais de diagnostic médical.`;

    const messages: OpenAIMessage[] = [{ role: 'system', content: systemPrompt }];
    for (const h of history.slice(-10)) messages.push({ role: h.role === 'model' ? 'assistant' : 'user', content: h.content });
    messages.push({ role: 'user', content: message });

    const tools = [{
      type: 'function',
      function: {
        name: 'add_routine_task',
        description: "Ajoute une tâche dans l'agenda quotidien de l'enfant.",
        parameters: { type: 'object', properties: {
          childId: { type: 'string', description: "ID de l'enfant" },
          title: { type: 'string', description: 'Titre de la tâche' },
          time: { type: 'string', description: 'Heure HH:mm' },
        }, required: ['childId', 'title', 'time'] },
      },
    }];

    let responseMessage = await this.tryProviders(messages, tools, userName);

    if (responseMessage.tool_calls?.length > 0) {
      messages.push(responseMessage);
      for (const toolCall of responseMessage.tool_calls) {
        if (toolCall.function.name === 'add_routine_task') {
          try {
            const args = JSON.parse(toolCall.function.arguments);
            const result = await this.executeAddRoutineTask(userId, args.childId, args.title, args.time);
            messages.push({ role: 'tool', tool_call_id: toolCall.id, content: result });
          } catch (e: any) {
            messages.push({ role: 'tool', tool_call_id: toolCall.id, content: JSON.stringify({ error: e.message }) });
          }
        }
      }
      responseMessage = await this.tryProviders(messages, tools, userName);
    }

    return responseMessage.content?.trim() || "Je n'ai rien à dire.";
  }

  private async tryProviders(messages: OpenAIMessage[], tools: any[], userName: string): Promise<any> {
    if (this.groqApiKey) {
      try { return await this.callAPI('https://api.groq.com/openai/v1/chat/completions', this.groqApiKey, 'llama-3.3-70b-versatile', messages, tools); }
      catch (err: any) { this.logger.warn(`Groq failed: ${err?.message}`); }
    }
    if (this.openaiApiKey) {
      try { return await this.callAPI('https://api.openai.com/v1/chat/completions', this.openaiApiKey, 'gpt-4o-mini', messages, tools); }
      catch (err: any) { throw new Error(`Désolé ${userName}, services AI indisponibles.`); }
    }
    throw new Error(`${userName}, aucune clé API configurée.`);
  }

  private async callAPI(url: string, apiKey: string, model: string, messages: OpenAIMessage[], tools: any[]): Promise<any> {
    const response = await axios.post(url, { model, messages, tools, tool_choice: 'auto', max_tokens: 512, temperature: 0.7 },
      { timeout: 20000, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` } });
    const msg = (response.data as any)?.choices?.[0]?.message;
    if (!msg) throw new Error('Empty response');
    return msg;
  }

  private async executeAddRoutineTask(userId: string, childId: string, title: string, time: string): Promise<string> {
    const child = await this.childModel.findOne({ _id: childId, parentId: userId }).lean().exec();
    if (!child) return JSON.stringify({ success: false, error: "Enfant non trouvé." });
    const task = new this.taskReminderModel({
      childId: new Types.ObjectId(childId), createdBy: new Types.ObjectId(userId),
      type: 'custom', title, frequency: 'once', times: [time],
      icon: '📅', color: '#A7DBE6', soundEnabled: true, vibrationEnabled: true, isActive: true,
    });
    await task.save();
    return JSON.stringify({ success: true, message: `Tâche '${title}' ajoutée à ${time} pour ${(child as any).fullName}.` });
  }
}
