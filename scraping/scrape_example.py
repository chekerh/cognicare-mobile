#!/usr/bin/env python3
"""
Example scraper scaffold for Tunisian training courses.
Outputs JSON compatible with CogniCare backend POST /api/v1/courses (admin).

Usage:
  pip install -r requirements.txt
  python scrape_example.py

Respect robots.txt and rate limits when targeting real sites.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urljoin, urlparse

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Install dependencies: pip install -r requirements.txt")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).resolve().parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)


def slugify(text: str) -> str:
    """Generate a URL-safe slug from title."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text[:80] or "course"


def scrape_example_site() -> list[dict]:
    """
    Placeholder: in production, replace with real site parsing.
    Returns list of course dicts for CogniCare API.
    """
    courses = []
    # Example: add one placeholder course to show structure
    courses.append({
        "title": "Formation Autisme – Niveau de base (exemple)",
        "description": "Formation d’introduction à l’accompagnement des enfants avec TSA. À remplacer par des données réelles scrapées.",
        "slug": "formation-autisme-base-exemple",
        "isQualificationCourse": False,
        "startDate": None,
        "endDate": None,
        "courseType": "basic",
        "price": "Gratuit",
        "location": None,
        "enrollmentLink": None,
        "certification": "Attestation de participation",
        "targetAudience": "volunteers, parents",
        "prerequisites": "Aucun",
        "sourceUrl": "https://example.com/formation",
    })
    return courses


def main():
    courses = scrape_example_site()
    # Optional: filter by date, dedupe by slug, etc.

    out = {"courses": courses, "scrapedAt": datetime.utcnow().isoformat() + "Z"}
    filename = OUTPUT_DIR / f"courses_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.json"
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"Written {len(courses)} course(s) to {filename}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
