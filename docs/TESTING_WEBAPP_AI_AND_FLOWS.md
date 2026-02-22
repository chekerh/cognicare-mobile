# Testing Guide – Web App (cognicareweb) – AI & Flows

Use this guide to verify AI recommendations, parent feedback, specialist preferences, admin/org views, and real-time behavior **in the web app**.

**React web app (cognicareweb):** Run with `npm run dev` (e.g. http://localhost:5175). Routes:
- **`/specialist/dashboard`** – Specialist dashboard (overview, children, my plans). Now includes **Suggestions d'activités** and a **Recommandations IA** button when a child is selected.
- **`/healthcare/dashboard`** – Renders the same specialist dashboard (no longer a blank page).
- **`/healthcare`** – Redirects to `/specialist/dashboard`.
- **`/specialist/ai-recommendations/:childId`** – AI recommendations for a child (summary, milestones, predictions, Approve/Modify/Dismiss with results improved and parent feedback questions).

**Prerequisites**

- Backend running (e.g. `http://localhost:3000` or your Render URL).
- Flutter app configured with the same `BASE_URL` (e.g. `--dart-define=BASE_URL=https://your-backend.onrender.com`).
- Test users: at least one **specialist** (e.g. psychologist), one **family** (parent), one **organization_leader**, one **admin**.

---

## 1. Specialist: AI recommendations (web app)

**Goal:** Real-time AI recommendations per plan type, Approve/Modify/Dismiss, milestones and progress bars.

1. **Log in as a specialist** (psychologist, speech_therapist, doctor, etc.).
   - You should land on **Healthcare Dashboard** (`/healthcare/dashboard`). If you see Volunteer “Accueil” instead, open manually: `/healthcare/dashboard`.
2. **Open the patients list**
   - Click **“Voir tout”** next to “Mes Patients” or go to **Patients** in the healthcare nav.
   - You should see **Filters**: “Type de plan” (Tous, PECS, TEACCH, Skill Tracker, Activité) and “Progrès” (Tous, Besoin d’attention, En bonne voie). Use them and confirm the list updates.
3. **Open AI recommendations for a child**
   - Click a patient card, then in the Care Board (or patient flow) open **“Recommandations IA”** / **AI Recommendations** for that child (route: `/healthcare/ai-recommendations/<childId>`).
4. **Check recommendations UI**
   - Summary, recommendations per plan type (PECS, TEACCH, etc.), **milestones** and **predictions** text.
   - **Progress bars** per plan (from plan data).
5. **Approve / Modify / Dismiss**
   - For one recommendation: **Approuver** → “Résultats améliorés?” → Oui/Non → optionally “Le retour du parent a-t-il été utile?” → Oui/Non/Passer.
   - **Modifier** → edit text → submit → same “Résultats améliorés?” and parent feedback questions.
   - **Dismiss** (no follow-up).
6. **Real-time / refresh**
   - Wait ~30 s or switch tab and come back: recommendations should refresh (polling + on-resume).
   - Confirm no “RIGHT OVERFLOWED” error on the screen.

**If something fails**

- 403 on `/healthcare/*`: ensure backend allows your role (psychologist, speech_therapist, etc.) for Progress AI and specialized-plans endpoints.
- Empty recommendations: child must have at least one active plan and the backend LLM must be configured (e.g. OpenAI key).
- Filters empty: backend `GET /organization/my-organization/children-with-plans` must return `planTypes` and `needAttention`.

---

## 2. Specialist: Activity suggestions & preferences (web app)

**Goal:** Activity suggestions on dashboard; specialist preferences influence AI.

1. On **Healthcare Dashboard** (`/healthcare/dashboard`), find the **“Suggestions d’activités”** card.
   - It should load 2–3 bullet tips (from `GET /progress-ai/activity-suggestions`).
   - “Voir patients” should go to the patients list.
2. **Preferences** (if the UI exposes them):
   - Open specialist preferences (e.g. from profile or AI section).
   - Set focus plan types, summary length, frequency.
   - Re-open AI recommendations for a child and confirm the request uses these preferences (e.g. in API query params).

---

## 3. Parent: Task completion, feedback, progress & AI summary (web app)

**Goal:** Task history with feedback, progress charts, AI summary for parents.

1. **Log in as family (parent)**.
2. **Daily routine / tasks**
   - Open the child’s daily routine (tasks).
   - Complete a task **with optional feedback** (text field).
   - Confirm completion is saved and, if your app shows it, “Vos retours récents” or equivalent displays the feedback.
3. **Progress summary**
   - From family dashboard or child context, open **“Résumé de progrès”** / **“Progrès de l’enfant”** (route like `/family/child-progress-summary` with child id).
   - You should see:
     - **Plan progress** (PECS, TEACCH, etc.) from `GET /specialized-plans/child/:childId/progress-summary` (if the child has plans).
     - **Task completion** (e.g. last 7/14 days) from reminder stats.
4. **AI summary (week/month)**
   - On the same progress screen, use **“Résumé IA”** with segment **Semaine** / **Mois** and **Refresh**.
   - After “Générer le résumé” or auto-load, a short AI summary should appear (from `GET /progress-ai/child/:childId/parent-summary?period=week|month`).
   - If it fails: check backend has parent summary implemented and family role is allowed.

---

## 4. Data flow and synchronization (web ↔ backend)

**Goal:** Data is up to date when new feedback, trials, or progress are entered.

1. **Polling**
   - On the **AI recommendations** screen, leave it open; recommendations refresh every **30 s**.
   - After submitting feedback (approve/modify/dismiss), within 30 s the list/counts should reflect it (or after manual refresh).
2. **On-resume**
   - Open AI recommendations, then switch to another browser tab for a few seconds, then switch back: a refresh should run (on-resume).
3. **Parent → specialist**
   - As parent: add task feedback.
   - As specialist: open the same child’s AI recommendations; the context sent to the LLM should include recent parent feedback (and possibly “request parent feedback” flow). No WebSockets are required for basic behavior; polling is enough.

---

## 5. Admin and organization views (web app)

**Goal:** Aggregated, non-PII data; org leader sees specialist summaries with approval and results-improved rates.

1. **Admin**
   - Log in as **admin**.
   - Open the **Progress AI Summary** (or equivalent) view.
   - You should see **global** counts (e.g. plan counts by type, total plans, children with plans). **No** child IDs, no org IDs in the main summary.
   - If implemented: open **summary by organization** (e.g. `GET /progress-ai/admin/summary-by-org`). Response should be per-org counts only (orgId + counts), no PII.
2. **Organization leader**
   - Log in as **organization_leader**.
   - Open the **Organization Dashboard** (or “Progress AI – Specialist summary” section).
   - Enter a **Specialist ID** (a user id of a psychologist/speech_therapist in your org) and load summary.
   - You should see: **Total plans**, **Children (anonymized)**, **Plan count by type** (chips), and, if the backend returns them, **“Taux d’approbation: X%”** and **“Résultats améliorés: Y%”**.

---

## 6. Backend integration checklist (APIs used by the web app)

Use the browser devtools **Network** tab while testing:

| Feature | Method & path | Role |
|--------|----------------|------|
| AI recommendations | `GET /progress-ai/child/:childId/recommendations` | specialist |
| Submit feedback | `POST /progress-ai/recommendations/:id/feedback` | specialist |
| Activity suggestions | `GET /progress-ai/activity-suggestions` | specialist |
| Specialist preferences | `GET/PATCH /progress-ai/preferences` | specialist |
| Parent progress summary | `GET /specialized-plans/child/:childId/progress-summary` | family |
| Parent AI summary | `GET /progress-ai/child/:childId/parent-summary?period=week\|month` | family |
| Children with plans (filters) | `GET /organization/my-organization/children-with-plans` | specialist |
| Reminder stats | `GET /reminders/child/:childId/stats?days=N` | (per your API) |
| Admin summary | `GET /progress-ai/admin/summary` | admin |
| Admin summary by org | `GET /progress-ai/admin/summary-by-org` | admin |
| Org specialist summary | `GET /progress-ai/org/specialist/:specialistId/summary` | organization_leader |

Confirm that responses are 200 and that request headers include a valid JWT for the correct role.

---

## 7. UI/UX quick checks

- **Specialist dashboard (web):** Real-time recommendations are on the **child-level** screen (AI recommendations), not on the main dashboard; the main dashboard has “Suggestions d’activités” and “Mes Patients” with filters.
- **Parent dashboard:** Progress is on the **child progress summary** screen (progress bars + task completion + AI summary).
- **Overflow:** After the fix, the **Volunteer/Accueil** screen (e.g. “Mes Patients” with “DN: …”) should not show “RIGHT OVERFLOWED BY 155 PIXEL”; if it does, report the exact route and widget (e.g. header row or patient card).

---

## 8. Specialist access to healthcare (web)

- **Psychologist / speech_therapist / etc.** now land on **Healthcare Dashboard** after login and can open **/healthcare/** routes (patients, AI recommendations, etc.).
- If you still see only Volunteer “Accueil”, navigate manually to **/healthcare/dashboard** and confirm you are not redirected away.

---

## Summary: what to test first in the web app

1. **Specialist:** Login → Healthcare Dashboard → Patients (with filters) → open one child → AI Recommendations → Approve/Modify/Dismiss and parent-feedback questions.
2. **Specialist:** Activity suggestions card on dashboard.
3. **Parent:** Complete task with feedback → open child progress summary → plan progress + task stats + AI summary (week/month).
4. **Org leader:** Specialist summary by ID with approval rate and results-improved rate.
5. **Admin:** Global summary (and summary-by-org if implemented).
6. **No overflow** on Accueil when opening it (e.g. from volunteer nav).

Use this to verify that what was implemented works end-to-end in the web app and to narrow down any failing step (UI vs API vs role).
