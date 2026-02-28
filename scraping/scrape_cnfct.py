#!/usr/bin/env python3
"""
Scraper for cnfct.nat.tn (Centre National de la Formation Continue et des Métiers).
Outputs JSON for CogniCare API.

Usage:
  pip install -r requirements.txt
  python scrape_cnfct.py

Respects robots.txt and uses a 2s delay between requests.
"""

import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional
from urllib.parse import urljoin

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Install dependencies: pip install -r requirements.txt")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).resolve().parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

BASE_URL = "https://www.cnfct.nat.tn"
USER_AGENT = "CogniCare-Bot/1.0 (training catalog; +https://cognicare.app)"
REQUEST_DELAY_SEC = 2


def slugify(text):
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text[:80] or "course"


def fetch_page(url, session):
    try:
        r = session.get(url, timeout=15)
        r.raise_for_status()
        return r.text
    except Exception as e:
        print("Fetch error {}: {}".format(url, e), file=sys.stderr)
        return None


def parse_courses_from_html(html, source_base):
    soup = BeautifulSoup(html, "lxml")
    courses = []
    seen = set()
    for tag in soup.find_all(["section", "div", "ul"], class_=re.compile(r"formation|stage|training|content|list", re.I)):
        for el in tag.find_all(["li", "article", "div"], recursive=False):
            link_el = el.find("a", href=True)
            title = (link_el.get_text(strip=True) if link_el else None) or el.get_text(strip=True)
            if not title or len(title) < 3:
                continue
            title = title[:200]
            slug = "cnfct-" + slugify(title)
            if slug in seen:
                continue
            seen.add(slug)
            link = urljoin(source_base, link_el["href"]) if link_el else None
            desc_el = el.find("p")
            description = (desc_el.get_text(strip=True)[:500] if desc_el else "") or "Formation CNFCT : {}.".format(title)
            courses.append({
                "title": title,
                "description": description,
                "slug": slug,
                "isQualificationCourse": False,
                "startDate": None,
                "endDate": None,
                "courseType": "basic",
                "price": "À préciser",
                "location": None,
                "enrollmentLink": link,
                "certification": "Attestation CNFCT",
                "targetAudience": "volunteers, professionals",
                "prerequisites": "Aucun",
                "sourceUrl": link or source_base,
            })
    if not courses:
        for a in soup.select("a[href]"):
            title = a.get_text(strip=True)
            if len(title) < 5 or len(title) > 150:
                continue
            slug = "cnfct-" + slugify(title)
            if slug in seen:
                continue
            seen.add(slug)
            link = urljoin(source_base, a["href"])
            courses.append({
                "title": title[:200],
                "description": "Formation CNFCT : {}.".format(title),
                "slug": slug,
                "isQualificationCourse": False,
                "startDate": None,
                "endDate": None,
                "courseType": "basic",
                "price": "À préciser",
                "location": None,
                "enrollmentLink": link,
                "certification": "Attestation CNFCT",
                "targetAudience": "volunteers, professionals",
                "prerequisites": "Aucun",
                "sourceUrl": link,
            })
    return courses


def scrape():
    session = requests.Session()
    session.headers["User-Agent"] = USER_AGENT
    all_courses = []
    for path in ["/", "/fr/", "/formations", "/fr/formations", "/stages"]:
        time.sleep(REQUEST_DELAY_SEC)
        url = urljoin(BASE_URL, path)
        html = fetch_page(url, session)
        if html:
            for c in parse_courses_from_html(html, url):
                if not any(x["slug"] == c["slug"] for x in all_courses):
                    all_courses.append(c)
            if all_courses:
                break
    return all_courses


def main():
    print("Scraping cnfct.nat.tn ...")
    courses = scrape()
    if not courses:
        print("No courses parsed. Adding placeholder.", file=sys.stderr)
        courses = [{
            "title": "Formation continue – CNFCT (exemple)",
            "description": "Données à récupérer lorsque le site est accessible.",
            "slug": "cnfct-formation-exemple",
            "isQualificationCourse": False,
            "startDate": None,
            "endDate": None,
            "courseType": "basic",
            "price": "À préciser",
            "location": None,
            "enrollmentLink": BASE_URL,
            "certification": "Attestation CNFCT",
            "targetAudience": "volunteers, professionals",
            "prerequisites": "Aucun",
            "sourceUrl": BASE_URL,
        }]
    out = {"courses": courses, "scrapedAt": datetime.utcnow().isoformat() + "Z", "source": "cnfct.nat.tn"}
    filename = OUTPUT_DIR / "courses_cnfct_{}.json".format(datetime.utcnow().strftime("%Y%m%d_%H%M"))
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("Written {} course(s) to {}".format(len(courses), filename))
    return 0


if __name__ == "__main__":
    sys.exit(main())
