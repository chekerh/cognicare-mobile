import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import { ProgressContext } from './progress-context.service';

const GEMINI_TIMEOUT = 30000;

interface GeminiContent {
  parts: Array<{ text: string }>;
}

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
}

export interface LlmPreferences {
  focusPlanTypes?: string[];
  summaryLength?: 'short' | 'detailed';
  /** Weights per plan type (e.g. { PECS: 1.2 }). Higher = more emphasis in output. */
  planTypeWeights?: Record<string, number>;
}

export interface LlmRecommendation {
  summary: string;
  recommendations: Array<{ planType: string; text: string }>;
  milestones?: string;
  /** Optional predictions / milestone estimates as free text */
  predictions?: string;
}

@Injectable()
export class LlmService {
  private readonly logger = new Logger(LlmService.name);
  private readonly apiKey = process.env.GEMINI_API_KEY;
  private readonly model =
    process.env.PROGRESS_AI_MODEL?.trim() || 'gemini-1.5-flash';
  private readonly url = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent`;

  async generateRecommendations(
    context: ProgressContext,
    preferences?: LlmPreferences,
  ): Promise<LlmRecommendation> {
    const prompt = this.buildPrompt(context, preferences);
    const raw = await this.callModel(prompt);
    return this.parseResponse(raw);
  }

  /**
   * Parent-facing summary: encouraging, non-clinical text for the given period.
   */
  async generateParentSummary(
    period: 'week' | 'month',
    context: {
      childAgeYears: number;
      diagnosis?: string;
      totalTasks: number;
      completedTasks: number;
      completionRate: number;
      planProgress: Array<{ type: string; title: string; progressPercent: number }>;
      recentFeedbackSnippets: string[];
    },
  ): Promise<string> {
    const periodLabel = period === 'week' ? 'cette semaine' : 'ce mois';
    const json = JSON.stringify(context, null, 2).slice(0, 4000);
    const prompt = `You are a supportive assistant for parents of children in care. Based on the following anonymized progress data for ${periodLabel}, write a short, encouraging summary (2-4 sentences) for the parent. Focus on:
- What went well (task completion, progress by plan type).
- One simple, positive suggestion for home (e.g. keep up the routine, try one more activity together).
Use warm, non-clinical language. Do not diagnose or give medical advice. Write in the same language as the user (if French data, respond in French).

Data (JSON):
${json}

Respond with only the summary text, no JSON and no preamble.`;
    if (!this.apiKey) {
      return `Résumé non disponible (configuration IA manquante). Vous avez complété ${context.completedTasks} tâches sur ${context.totalTasks} ${periodLabel}.`;
    }
    try {
      const raw = await this.callModel(prompt);
      return raw.trim().slice(0, 800) || `Progression: ${context.completedTasks}/${context.totalTasks} tâches. Continuez comme ça !`;
    } catch {
      return `Progression ${periodLabel}: ${context.completedTasks} tâches complétées sur ${context.totalTasks}. Continuez comme ça !`;
    }
  }

  private buildPrompt(
    context: ProgressContext,
    preferences?: LlmPreferences,
  ): string {
    const focusHint = preferences?.focusPlanTypes?.length
      ? `Focus your recommendations on these plan types: ${preferences.focusPlanTypes.join(
          ', ',
        )}.`
      : '';
    const lengthHint =
      preferences?.summaryLength === 'short'
        ? 'Keep each recommendation to 1–2 sentences.'
        : preferences?.summaryLength === 'detailed'
          ? 'Provide detailed recommendations with concrete next steps.'
          : '';
    const weights = preferences?.planTypeWeights;
    const weightsHint =
      weights && Object.keys(weights).length > 0
        ? `Give extra emphasis to these plan types (higher weight = more detail and priority): ${JSON.stringify(weights)}.`
        : '';

    const contextPayload: Record<string, unknown> = {
      child: context.child,
      plans: context.plans,
      taskReminders: context.taskReminders,
    };
    if (context.progressNumericSummary) {
      contextPayload.progressNumericSummary = context.progressNumericSummary;
    }
    const contextJson = JSON.stringify(contextPayload, null, 2);

    return `You are an expert in autism interventions (PECS, TEACCH, skill tracking, and home activities).
You receive anonymized JSON data describing a child, their specialized plans (PECS, TEACCH, SkillTracker, Activity),
their home routines / reminders, and an optional progressNumericSummary (trials pass/total, goals at target, etc.).

Use this data to:
- Give personalized, concrete feedback per plan type (PECS, TEACCH, SkillTracker, Activity).
- Take into account parent-reported feedback on activities and low adherence patterns.
- Infer next-phase timing from trial and goal data: e.g. from PECS trialsPass/trialsTotal estimate "Phase 2 likely in ~X sessions if current rate continues"; from TEACCH goals estimate "Goal Y likely in ~Z weeks". Use progressNumericSummary when present for consistent estimates.
- Include 1–2 short bullets on what is working well and what needs improvement (e.g. "Increase number of card trials for PECS Phase 2"; "Focus on social skills goal in TEACCH").
- Predict likely short-term milestones based on recent progress trends.

${focusHint}
${lengthHint}
${weightsHint}

Progress data (JSON):
${contextJson.slice(0, 12000)}

Respond with a valid JSON object in this exact format (no markdown, no code block):
{
  "summary": "One paragraph overall assessment. Include 1–2 bullets on what's working and what needs improvement, then main areas to focus on.",
  "recommendations": [
    { "planType": "PECS", "text": "Specific, actionable recommendation for PECS (e.g. increase Phase 2 trials, add picture choices)." },
    { "planType": "TEACCH", "text": "Recommendation for TEACCH goals." },
    { "planType": "SkillTracker", "text": "Recommendation for skill tracker." },
    { "planType": "Activity", "text": "Recommendation for activities and home practice." }
  ],
  "milestones": "1–2 sentences on key milestones already achieved or immediately ahead.",
  "predictions": "1–3 sentences with progress forecasting for each relevant plan type. Give approximate timing when possible (e.g. 'PECS: Phase 2 likely in ~5 sessions if trial success rate continues. TEACCH: Academics goal may reach target in 2 weeks. SkillTracker: mastery likely in 3 sessions. Activity: suggest simpler home tasks if parent reports difficulty.')."
}

Rules:
- Provide exactly one recommendation per plan type (PECS, TEACCH, SkillTracker, Activity) that appears in the plans array; use brief placeholder text only if no data for that type.
- Always include milestones and predictions when any plan data exists; base forecasts on progressNumericSummary and recent progress; give approximate session/week estimates where data allows.
- Use short, actionable language.`;
  }

  private async callModel(prompt: string): Promise<string> {
    if (!this.apiKey) {
      this.logger.warn('GEMINI_API_KEY not set; returning placeholder');
      return JSON.stringify({
        summary:
          'AI recommendations are not configured. Set GEMINI_API_KEY to enable.',
        recommendations: [],
        milestones: '',
        predictions: '',
      });
    }

    try {
      const response = await axios.post<GeminiResponse>(
        `${this.url}?key=${this.apiKey}`,
        {
          contents: [{ parts: [{ text: prompt }] }],
        },
        {
          timeout: GEMINI_TIMEOUT,
          headers: { 'Content-Type': 'application/json' },
        },
      );
      const text =
        response.data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
      if (!text) throw new Error('Empty response from LLM');
      return text;
    } catch (err: any) {
      this.logger.error(`LLM call failed: ${err?.message ?? err}`);
      throw err;
    }
  }

  private parseResponse(raw: string): LlmRecommendation {
    try {
      const cleaned = raw
        .replace(/```json\s*/gi, '')
        .replace(/```\s*/g, '')
        .trim();
      const parsed = JSON.parse(cleaned);

      const summary =
        typeof parsed.summary === 'string'
          ? parsed.summary
          : 'No summary available.';
      let recs = Array.isArray(parsed.recommendations)
        ? parsed.recommendations
        : [];
      recs = recs.filter(
        (r: any) =>
          r && typeof r.planType === 'string' && typeof r.text === 'string',
      );

      const milestones =
        typeof parsed.milestones === 'string' ? parsed.milestones : undefined;
      const predictions =
        typeof parsed.predictions === 'string' ? parsed.predictions : undefined;

      return { summary, recommendations: recs, milestones, predictions };
    } catch {
      return {
        summary: raw.slice(0, 500) || 'Unable to parse AI response.',
        recommendations: [],
        milestones: undefined,
        predictions: undefined,
      };
    }
  }
}

