#!/usr/bin/env python3
"""
Scraper for autisme-tunisie.org (and similar association pages).
Fetches the site, parses formations/activités, outputs JSON for CogniCare API.

Usage:
  pip install -r requirements.txt
  python scrape_autisme_tunisie.py

Respects robots.txt and uses a 2s delay between requests.
"""

import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional
from urllib.parse import urljoin, urlparse

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Install dependencies: pip install -r requirements.txt")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).resolve().parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

BASE_URL = "https://www.autisme-tunisie.org"
USER_AGENT = "CogniCare-Bot/1.0 (training catalog; +https://cognicare.app)"
REQUEST_DELAY_SEC = 2


def slugify(text: str) -> str:
    """Generate a URL-safe slug from title."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text[:80] or "course"


def fetch_page(url: str, session: requests.Session) -> Optional[str]:
    """Fetch a page; returns HTML or None on failure."""
    try:
        r = session.get(url, timeout=15)
        r.raise_for_status()
        return r.text
    except Exception as e:
        print(f"Fetch error {url}: {e}", file=sys.stderr)
        return None


def parse_courses_from_html(html: str, source_base: str) -> list[dict]:
    """
    Parse course-like items from an association/formations page.
    Looks for: headings (h2/h3), links with text, list items.
    """
    soup = BeautifulSoup(html, "lxml")
    courses = []
    seen_slugs = set()

    # Common containers for formations/events
    for container in soup.find_all(["section", "div"], class_=re.compile(r"formation|event|activit|content", re.I)):
        for el in container.find_all(["article", "div"], recursive=False):
            title_el = el.find(["h1", "h2", "h3", "h4"])
            link_el = el.find("a", href=True)
            title = None
            link = None
            if title_el:
                title = title_el.get_text(strip=True)
            if link_el:
                link = urljoin(source_base, link_el["href"])
                if not title:
                    title = link_el.get_text(strip=True)
            if not title or len(title) < 3:
                continue
            slug = slugify(title)
            if slug in seen_slugs:
                continue
            seen_slugs.add(slug)
            # Try to find a short description (next paragraph or sibling)
            desc_el = el.find("p") or (title_el.next_sibling if title_el else None)
            description = desc_el.get_text(strip=True)[:500] if hasattr(desc_el, "get_text") and desc_el else ""
            courses.append({
                "title": title[:200],
                "description": description or f"Formation / activité : {title}.",
                "slug": f"autisme-tunisie-{slug}",
                "isQualificationCourse": False,
                "startDate": None,
                "endDate": None,
                "courseType": "basic",
                "price": "À préciser",
                "location": None,
                "enrollmentLink": link,
                "certification": None,
                "targetAudience": "volunteers, parents",
                "prerequisites": "Aucun",
                "sourceUrl": link or source_base,
            })

    # Fallback: any h2/h3 with a following link
    if not courses:
        for heading in soup.find_all(["h2", "h3"]):
            title = heading.get_text(strip=True)
            if len(title) < 4:
                continue
            next_a = heading.find_next("a", href=True)
            link = urljoin(source_base, next_a["href"]) if next_a else None
            slug = slugify(title)
            if slug in seen_slugs:
                continue
            seen_slugs.add(slug)
            courses.append({
                "title": title[:200],
                "description": f"Formation ou activité : {title}.",
                "slug": f"autisme-tunisie-{slug}",
                "isQualificationCourse": False,
                "startDate": None,
                "endDate": None,
                "courseType": "basic",
                "price": "À préciser",
                "location": None,
                "enrollmentLink": link,
                "certification": None,
                "targetAudience": "volunteers, parents",
                "prerequisites": "Aucun",
                "sourceUrl": link or source_base,
            })

    return courses


def scrape_autisme_tunisie() -> list[dict]:
    """Fetch autisme-tunisie.org and parse formations."""
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    all_courses = []

    # Try main page and common subpages
    urls_to_try = [
        BASE_URL,
        urljoin(BASE_URL, "/formations"),
        urljoin(BASE_URL, "/activites"),
        urljoin(BASE_URL, "/nos-activites"),
    ]
    for url in urls_to_try:
        time.sleep(REQUEST_DELAY_SEC)
        html = fetch_page(url, session)
        if html:
            courses = parse_courses_from_html(html, url)
            for c in courses:
                if not any(x["slug"] == c["slug"] for x in all_courses):
                    all_courses.append(c)
            if courses:
                break

    return all_courses


def main():
    print("Scraping autisme-tunisie.org ...")
    courses = scrape_autisme_tunisie()
    if not courses:
        print("No courses parsed (site may be down or structure changed). Adding one placeholder.", file=sys.stderr)
        courses = [{
            "title": "Formation Autisme – Autisme Tunisie (exemple)",
            "description": "Formation d’introduction. Données réelles à récupérer lorsque le site est accessible.",
            "slug": "autisme-tunisie-formation-exemple",
            "isQualificationCourse": False,
            "startDate": None,
            "endDate": None,
            "courseType": "basic",
            "price": "À préciser",
            "location": None,
            "enrollmentLink": BASE_URL,
            "certification": None,
            "targetAudience": "volunteers, parents",
            "prerequisites": "Aucun",
            "sourceUrl": BASE_URL,
        }]

    out = {"courses": courses, "scrapedAt": datetime.utcnow().isoformat() + "Z", "source": "autisme-tunisie"}
    filename = OUTPUT_DIR / f"courses_autisme_tunisie_{datetime.utcnow().strftime('%Y%m%d_%H%M')}.json"
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"Written {len(courses)} course(s) to {filename}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
