# Scraping – Formations Tunisie (autisme & éducation spécialisée)

Ce dossier contient les scripts et la documentation pour récupérer les formations depuis des sites tunisiens officiels et les intégrer au catalogue CogniCare.

## Sites cibles

- www.femmes.gov.tn
- www.autisme-tunisie.org
- www.fsje.rnu.tn
- www.cnfct.nat.tn
- www.centrehalim.com
- www.itfs.tn
- www.basmaassociation.org
- www.education.tn
- www.manouba.tn
- www.tadf.tn

## Données à extraire

Pour chaque formation :

- **Course Name** (title)
- **Description**
- **Start / End Dates**
- **Course Type** (basic, advanced)
- **Price** (si disponible)
- **Location** (si présentiel)
- **Link to enrollment** (enrollmentLink)
- **Certification** (diplôme / attestation)
- **Target Audience** (bénévoles, parents, professionnels)
- **Prerequisites**
- **sourceUrl** (URL de la page source)

## Structure JSON (sortie scraper)

Les scripts produisent des fichiers JSON compatibles avec l’API d’import :

```json
{
  "courses": [
    {
      "title": "Nom du cours",
      "description": "...",
      "slug": "nom-du-cours-unique",
      "isQualificationCourse": false,
      "startDate": "2025-03-01",
      "endDate": "2025-03-15",
      "courseType": "basic",
      "price": "Gratuit",
      "location": "Tunis",
      "enrollmentLink": "https://...",
      "certification": "Attestation reconnue",
      "targetAudience": "volunteers, parents",
      "prerequisites": "Aucun",
      "sourceUrl": "https://..."
    }
  ]
}
```

## Utilisation

### 1. Environnement Python

```bash
cd scraping
python -m venv venv
source venv/bin/activate   # ou venv\Scripts\activate sur Windows
pip install -r requirements.txt
```

### 2. Lancer un scraper

- **Exemple (données de démo)**  
  `python scrape_example.py` → `output/courses_YYYYMMDD_HHMM.json`

- **Autisme Tunisie**  
  `python scrape_autisme_tunisie.py` → `output/courses_autisme_tunisie_YYYYMMDD_HHMM.json`

- **Femmes.gov.tn**  
  `python scrape_femmes_gov_tn.py` → `output/courses_femmes_gov_YYYYMMDD_HHMM.json`

- **CNFCT (Centre National de la Formation Continue)**  
  `python scrape_cnfct.py` → `output/courses_cnfct_YYYYMMDD_HHMM.json`  

  Si un site est injoignable, le script écrit un cours exemple pour valider le flux.

### 3. Importer dans CogniCare

- **Option A – API Admin**  
  Envoyer chaque cours en `POST /api/v1/courses` (Admin, JWT) avec le body JSON du cours.

- **Option B – Script d’import**  
  À prévoir : script Node qui lit le JSON et appelle l’API ou insère en base.

## Règles et éthique

- Respecter `robots.txt` et les conditions d’utilisation des sites.
- Limiter la fréquence des requêtes (délai entre requêtes).
- Ne pas surcharger les serveurs cibles.
- Vérifier la légalité et la pertinence des attestations/certifications avant de les afficher.

## Planification (Celery / cron)

Pour une mise à jour régulière :

1. Exécuter le scraper (cron ou tâche planifiée).
2. Comparer avec les cours déjà en base (slug, sourceUrl).
3. Créer les nouveaux cours via l’API ou un script d’import.
4. Marquer ou archiver les formations expirées (endDate < today).
