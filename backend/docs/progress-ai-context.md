# Progress AI Context Contract

This document describes the JSON structure that the `progress-ai` module builds
for each child before calling the LLM. It is intended as a stable contract
between the backend, the AI provider, and any future dashboards.

The context is produced by
[`backend/src/progress-ai/progress-context.service.ts`](../src/progress-ai/progress-context.service.ts)
and has the following TypeScript shape:

```ts
export interface ProgressContext {
  child: {
    /** Derived age in full years from dateOfBirth */
    ageYears: number;
    /** Optional diagnosis string (e.g. 'Autism Spectrum Disorder') */
    diagnosis?: string;
    /** 'male' | 'female' | 'other' */
    gender: string;
  };

  /**
   * All active specialized plans for the child.
   * The exact content shape depends on plan type.
   */
  plans: Array<{
    planId: string;
    /** 'PECS' | 'TEACCH' | 'SkillTracker' | 'Activity' */
    type: string;
    title: string;

    /**
     * Raw content as stored in MongoDB. By convention:
     *
     * type === 'PECS':
     *   {
     *     phaseName: string;
     *     items: Array<{
     *       id: string;
     *       label: string;
     *       imageUrl?: string;
     *       // 10 trials per card: 'pass' | 'fail' | null
     *       trials: Array<'pass' | 'fail' | null>;
     *     }>;
     *   }
     *
     * type === 'TEACCH':
     *   {
     *     goals: Array<{
     *       id: string;
     *       text: string;
     *       category?: string; // Social, Communication, Academics, etc.
     *       baseline?: number; // 0–100
     *       target?: number;   // 0–100
     *       current?: number;  // 0–100
     *       measurement?: string;
     *       lastUpdated?: string; // ISO date, if provided by client
     *     }>;
     *     workSystem?: {
     *       whatToDo?: string;
     *       howMuch?: string;
     *       whenDone?: string;
     *       whatNext?: string;
     *     };
     *   }
     *
     * type === 'SkillTracker':
     *   {
     *     trials?: Array<'success' | 'fail' | null>;
     *     successCount?: number;
     *     baselinePercent?: number;
     *     targetPercent?: number;
     *     currentPercent?: number;
     *     isMastered?: boolean;
     *   }
     *
     * type === 'Activity':
     *   {
     *     description: string;
     *     parentInstructions?: string;
     *     dueDate?: string; // ISO date
     *     status?: string; // 'pending' | 'completed' | etc.
     *     // Optional parent feedback about home practice
     *     parentFeedback?: string;
     *     // Optional timestamp when parent marked it completed
     *     completedAt?: string; // ISO date
     *   }
     */
    content: unknown;

    /**
     * Optional notes by the specialist about interventions used
     * (e.g. prompts, visual supports, strategies tried).
     */
    sessionNotes?: string;
  }>;

  /**
   * Active task reminders for the child (nutrition / routines / medication / activities).
   * These are used as a proxy for adherence and parent engagement.
   */
  taskReminders: Array<{
    title: string;
    type: string;
    completionSummary: {
      /** Total number of completionHistory entries */
      total: number;
      /** Number of completed entries */
      completed: number;
      /** Last ~14 days of completion flags */
      recent: Array<{
        /** ISO date (yyyy-mm-dd) */
        date: string;
        completed: boolean;
      }>;
      /** Number of entries that contain non-empty parent feedback text */
      feedbackCount: number;
      /** Latest short parent feedback snippet, if any */
      latestFeedback?: string;
    };
  }>;
}
```

The `ProgressContextService` is **stateless**: for each request it reads the
latest data from MongoDB (`children`, `specializedplans`, `taskreminders`) so
that AI feedback always reflects the most recent trials, goal updates, and
activity completions.

## Privacy

- **Admin**: `GET /progress-ai/admin/summary` returns cross-org aggregates only
  (plan counts by type, total plans, children-with-plans count). No PII, no
  child IDs, no organization IDs. Optional `GET /progress-ai/admin/summary-by-org`
  returns the same structure per organization (orgId + counts only; no child or
  specialist identities).
- **Org leader**: `GET /progress-ai/org-leader/specialist-summary/:specialistId`
  is scoped to the leader’s organization; response contains specialist-level
  counts and metrics only, no PII.
- Neither admin nor org-leader endpoints expose names, emails, or identifiers
  beyond orgId in the summary-by-org response.

