# Autism Training Scraper

Scrapes **official and reputable** autism training sources for the CogniCare caregiver training module. Content is structured for the backend Training API and must be **approved by professionals** before appearing in the app.

## Sources (respect robots.txt and ToS)

- **TEACCH** – https://teacch.com/
- **Autism Speaks – TEACCH** – https://www.autismspeaks.org/teacch
- **Autism Speaks – Caregiver Skills Training (WHO)** – https://www.autismspeaks.org/caregiver-skills-training-program
- **WHO – Caregiver Training** – https://www.who.int/news/item/31-03-2022-who-s-training-for-caregivers-of-children-with-autism-goes-online
- **National Autistic Society (UK)** – https://www.autism.org.uk/what-we-do/autism-know-how/training
- **NAS E-learning** – https://www.autism.org.uk/what-we-do/autism-know-how/training/e-learning
- **NHS England – Autism resources** – https://www.england.nhs.uk/learning-disabilities/about/useful-autism-resources-and-training/

## Setup

```bash
cd scripts/autism_training_scraper
python -m venv venv
source venv/bin/activate   # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

## Usage

- **Generate 3 courses from official scraped sites** (recommended for "cours générés depuis les sites scrapés"):
  ```bash
  python scraper.py --scrape-courses --out training_courses.json
  ```
  This fetches WHO, NAS, Autism Speaks, and TEACCH URLs from `config.py`, extracts sections, builds the 3 courses (General Autism, PECs, TEACCH) with our titles/descriptions/quizzes, and writes JSON ready for the backend. To feed the backend seed file directly:
  ```bash
  python scraper.py --scrape-courses --out ../../backend/data/training-courses-seed.json
  ```
  Then restart the backend (or clear the training collection and restart) so the seed loads the scraped content.

- **Templates only** (no network; outputs 3 course stubs with empty sections):
  ```bash
  python scraper.py --templates-only --out training_courses.json
  ```

- **Scrape one or more custom URLs**:
  ```bash
  python scraper.py --url "https://teacch.com/" "TEACCH Overview" --url "https://www.autismspeaks.org/teacch" "" --out training_courses.json
  ```

Output JSON matches the backend `POST /api/v1/training/admin/courses` body shape: `title`, `description`, `contentSections`, `sourceUrl`, `topics`, `quiz`, `approved`, `order`.

## Pre-generated courses (backend seed)

The backend can **auto-seed** 3 full courses (content + quiz) at startup if the training collection is empty. The data is in `backend/data/training-courses-seed.json` (Connaissances générales sur l'autisme, PECS, Méthode TEACCH). Start the backend from the `backend/` folder so that `data/training-courses-seed.json` is found. Then approve the courses in CogniWeb (Admin → Training Courses) to make them visible in the app.

## Importing into CogniCare (manual)

1. Get an admin JWT from CogniCare auth.
2. For each course in `training_courses.json`:
   ```bash
   curl -X POST https://your-api/api/v1/training/admin/courses \
     -H "Authorization: Bearer YOUR_ADMIN_JWT" \
     -H "Content-Type: application/json" \
     -d @course1.json
   ```
3. In CogniWeb admin, review and **approve** each course so it becomes visible in the app.

## Quiz generation

The scraper does not generate quiz questions. Add `quiz` entries when creating/updating courses via the admin API, or implement a separate step that derives multiple-choice questions from `contentSections` text (e.g. key facts and definitions).
