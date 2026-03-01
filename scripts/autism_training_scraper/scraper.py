"""
Scrape official autism training sources.
Extracts: titles, descriptions, sections (headings, paragraphs), video links, definitions.
Respects robots.txt (check with urllib.robotparser before fetching).
Output: JSON compatible with CogniCare backend training API (contentSections, quiz placeholder).
"""
from __future__ import annotations

import json
import re
import time
from typing import Any
from urllib.parse import urljoin, urlparse
from urllib.robotparser import RobotFileParser

import requests
from bs4 import BeautifulSoup

from config import (
    HEADERS,
    REQUEST_DELAY,
    WHO_CAREGIVER,
    NAS_TRAINING,
    AUTISM_SPEAKS_CST,
    AUTISM_SPEAKS_TEACCH,
    TEACCH_HOME,
)


def can_fetch(robot_parser: RobotFileParser, url: str, user_agent: str) -> bool:
    """Check robots.txt for URL and user agent."""
    try:
        return robot_parser.can_fetch(user_agent, url)
    except Exception:
        return True


def fetch_robots_txt(base_url: str) -> RobotFileParser:
    parsed = urlparse(base_url)
    robots_url = f"{parsed.scheme}://{parsed.netloc}/robots.txt"
    rp = RobotFileParser()
    try:
        rp.set_url(robots_url)
        rp.read()
    except Exception:
        pass
    return rp


def fetch_page(url: str) -> str | None:
    """Fetch HTML; respect robots.txt and delay."""
    parsed = urlparse(url)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    rp = fetch_robots_txt(origin)
    if not can_fetch(rp, url, HEADERS["User-Agent"]):
        print(f"Skip (robots.txt): {url}")
        return None
    time.sleep(REQUEST_DELAY)
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
        return r.text
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return None


def extract_sections(soup: BeautifulSoup) -> list[dict[str, Any]]:
    """Extract structured sections: headings, paragraphs, lists, links (including video)."""
    sections = []
    order = 0
    for tag in soup.find_all(["h1", "h2", "h3", "h4", "p", "ul", "ol"]):
        if tag.name in ("h1", "h2", "h3", "h4"):
            text = tag.get_text(strip=True)
            if not text:
                continue
            sections.append({
                "type": "text",
                "title": text,
                "content": "",
                "order": order,
            })
            order += 1
        elif tag.name == "p":
            text = tag.get_text(strip=True)
            if not text or len(text) < 10:
                continue
            # Detect video links
            video_url = None
            for a in tag.find_all("a", href=True):
                href = a.get("href", "")
                if "youtube" in href or "vimeo" in href or "video" in href.lower():
                    video_url = href if href.startswith("http") else urljoin(str(tag.base_url or ""), href)
                    break
            sections.append({
                "type": "video" if video_url else "text",
                "content": text,
                "videoUrl": video_url or None,
                "order": order,
            })
            order += 1
        elif tag.name in ("ul", "ol"):
            items = [li.get_text(strip=True) for li in tag.find_all("li") if li.get_text(strip=True)]
            if not items:
                continue
            sections.append({
                "type": "list",
                "listItems": items,
                "order": order,
            })
            order += 1
    return sections


def extract_definitions(soup: BeautifulSoup) -> list[dict[str, Any]]:
    """Find definition-like structures (dt/dd, strong + following text)."""
    sections = []
    order = 0
    dl = soup.find("dl")
    if dl:
        definitions = {}
        for dt, dd in zip(dl.find_all("dt"), dl.find_all("dd")):
            term = dt.get_text(strip=True)
            definition = dd.get_text(strip=True)
            if term and definition:
                definitions[term] = definition
        if definitions:
            sections.append({
                "type": "definition",
                "definitions": definitions,
                "order": order,
            })
            order += 1
    return sections


def scrape_url(url: str, title_override: str | None = None) -> dict[str, Any] | None:
    """Scrape one URL and return a course-like structure (no quiz; to be added manually or generated)."""
    html = fetch_page(url)
    if not html:
        return None
    soup = BeautifulSoup(html, "html.parser")
    # Remove script/style
    for t in soup(["script", "style"]):
        t.decompose()
    sections = extract_sections(soup)
    sections.extend(extract_definitions(soup))
    sections.sort(key=lambda s: s["order"])
    title = title_override or soup.find("title")
    title = title.get_text(strip=True) if hasattr(title, "get_text") else str(title) or url
    if len(title) > 200:
        title = title[:197] + "..."
    # Meta description
    desc = ""
    meta = soup.find("meta", attrs={"name": "description"}) or soup.find("meta", attrs={"property": "og:description"})
    if meta and meta.get("content"):
        desc = meta["content"].strip()[:1000]
    if not desc and sections:
        first_text = next((s.get("content") or s.get("title") or "" for s in sections if s.get("content") or s.get("title")), "")
        desc = first_text[:500] if isinstance(first_text, str) else ""
    return {
        "title": title,
        "description": desc or f"Training content from {url}",
        "contentSections": sections,
        "sourceUrl": url,
        "topics": [],
        "quiz": [],
        "approved": False,
        "order": 0,
    }


def _merge_sections(sections_list: list[list[dict[str, Any]]]) -> list[dict[str, Any]]:
    """Merge multiple section lists and renumber order."""
    out: list[dict[str, Any]] = []
    order = 0
    for sections in sections_list:
        for s in sections:
            s = dict(s)
            s["order"] = order
            order += 1
            out.append(s)
    return out


# Quiz questions (French) for each course — used when generating from scraped content
QUIZ_COURSE_1 = [
    {"question": "L'autisme est une condition qui affecte principalement :", "options": ["Uniquement le langage", "La communication, les interactions sociales et le comportement", "Uniquement la motricité", "Uniquement la vision"], "correctIndex": 1, "order": 0},
    {"question": "Pourquoi les routines sont-elles souvent utiles pour un enfant autiste ?", "options": ["Pour le fatiguer", "Elles réduisent l'anxiété en rendant le monde prévisible", "Pour le punir", "Les routines ne sont pas recommandées"], "correctIndex": 1, "order": 1},
    {"question": "Que faire en priorité pendant une crise (meltdown) ?", "options": ["Crier pour se faire entendre", "Assurer la sécurité et rester calme en attendant que ça passe", "Forcer l'enfant à s'arrêter", "Ignorer complètement"], "correctIndex": 1, "order": 2},
    {"question": "Le « stimming » désigne :", "options": ["Une maladie", "Des comportements répétitifs d'auto-stimulation qui aident à réguler", "Un médicament", "Une thérapie"], "correctIndex": 1, "order": 3},
    {"question": "Concernant l'alimentation des enfants autistes :", "options": ["Il faut toujours forcer à manger de tout", "Beaucoup ont des particularités (sélectivité) ; il faut proposer progressivement sans forcer", "Ils ne doivent pas manger de sucre du tout", "L'alimentation n'a pas d'impact"], "correctIndex": 1, "order": 4},
]
QUIZ_COURSE_2 = [
    {"question": "Le PECS est un système de communication basé sur :", "options": ["La parole uniquement", "L'échange d'une image contre un objet ou une action", "Le geste uniquement", "L'écriture"], "correctIndex": 1, "order": 0},
    {"question": "Pourquoi le PECS convient-il bien aux enfants autistes peu verbaux ?", "options": ["Parce qu'il exige d'abord la parole", "Parce qu'il s'appuie sur le visuel et ne demande pas d'imitation verbale au départ", "Parce qu'il remplace totalement la parole", "Parce qu'il est plus simple que la langue des signes"], "correctIndex": 1, "order": 1},
    {"question": "Dans la phase 1 du PECS, l'enfant apprend à :", "options": ["Lire des mots", "Donner une image pour obtenir l'objet désiré", "Parler à haute voix", "Écrire une phrase"], "correctIndex": 1, "order": 2},
    {"question": "Quel type de support est typiquement utilisé pour le PECS ?", "options": ["Un cahier d'écriture", "Un classeur avec images et bandes Velcro", "Une tablette sans images", "Un tableau noir"], "correctIndex": 1, "order": 3},
]
QUIZ_COURSE_3 = [
    {"question": "TEACCH est un programme qui :", "options": ["Se concentre uniquement sur la parole", "Adapte l'environnement et l'enseignement aux particularités des personnes autistes", "Exclut l'usage d'images", "N'est utilisé qu'à l'hôpital"], "correctIndex": 1, "order": 0},
    {"question": "L'emploi du temps visuel sert à :", "options": ["Remplacer l'école", "Montrer à l'enfant dans quel ordre vont se dérouler les activités pour le rassurer", "Punir l'enfant", "Réduire le temps de jeu"], "correctIndex": 1, "order": 1},
    {"question": "Le « système de travail » en TEACCH permet à l'enfant de :", "options": ["Jouer librement sans consigne", "Voir combien de tâches restent et ce qu'il faut faire (séquence claire)", "Éviter tout travail", "Travailler sans support visuel"], "correctIndex": 1, "order": 2},
    {"question": "La structure physique dans TEACCH consiste à :", "options": ["Construire un nouveau bâtiment", "Organiser l'espace en zones clairement identifiables (travail, jeu, repos)", "Supprimer tous les meubles", "Utiliser uniquement des couleurs sombres"], "correctIndex": 1, "order": 3},
]


def build_courses_from_live_scrape() -> list[dict[str, Any]]:
    """
    Generate the 3 courses by scraping the official URLs. Content comes from the sites;
    title, description, topics and quiz are set by us. Output is ready for backend seed or API.
    """
    courses = []

    # Course 1 — General Autism: WHO + NAS + Autism Speaks CST
    print("Scraping Course 1 (General Autism): WHO, NAS, Autism Speaks...")
    parts_1 = []
    for url in [WHO_CAREGIVER, NAS_TRAINING, AUTISM_SPEAKS_CST]:
        c = scrape_url(url, None)
        if c and c.get("contentSections"):
            parts_1.append(c["contentSections"])
    sections_1 = _merge_sections(parts_1) if parts_1 else [
        {"type": "text", "title": "Autism overview", "content": "Content from official sources (WHO, NAS, Autism Speaks). Run the scraper when the sites are reachable.", "order": 0},
    ]
    courses.append({
        "title": "Connaissances générales sur l'autisme",
        "description": "Vue d'ensemble de l'autisme, gestion au quotidien (comportement, routine, besoins sensoriels) et conseils nutritionnels. Contenu basé sur la formation OMS pour aidants, la National Autistic Society et Autism Speaks.",
        "contentSections": sections_1,
        "sourceUrl": WHO_CAREGIVER,
        "topics": ["autisme général", "compétences aidant", "OMS", "comportement", "nutrition"],
        "quiz": QUIZ_COURSE_1,
        "approved": True,
        "order": 1,
    })

    # Course 2 — PECs: Autism Speaks Caregiver Skills Training
    print("Scraping Course 2 (PECS): Autism Speaks CST...")
    c2 = scrape_url(AUTISM_SPEAKS_CST, None)
    sections_2 = c2["contentSections"] if c2 and c2.get("contentSections") else [
        {"type": "text", "title": "PECS / Communication", "content": "Content from Autism Speaks Caregiver Skills Training. Run the scraper when the site is reachable.", "order": 0},
    ]
    courses.append({
        "title": "PECs — Système de communication par échange d'images",
        "description": "Introduction au PECS, pourquoi il fonctionne pour les enfants non verbaux ou peu verbaux, et étapes pratiques pour le mettre en place avec des supports visuels.",
        "contentSections": sections_2,
        "sourceUrl": AUTISM_SPEAKS_CST,
        "topics": ["PECS", "communication", "support visuel"],
        "quiz": QUIZ_COURSE_2,
        "approved": True,
        "order": 2,
    })

    # Course 3 — TEACCH: TEACCH.com + Autism Speaks TEACCH
    print("Scraping Course 3 (TEACCH): TEACCH, Autism Speaks...")
    parts_3 = []
    for url in [TEACCH_HOME, AUTISM_SPEAKS_TEACCH]:
        c = scrape_url(url, None)
        if c and c.get("contentSections"):
            parts_3.append(c["contentSections"])
    sections_3 = _merge_sections(parts_3) if parts_3 else [
        {"type": "text", "title": "TEACCH structured teaching", "content": "Content from TEACCH and Autism Speaks. Run the scraper when the sites are reachable.", "order": 0},
    ]
    courses.append({
        "title": "Méthode TEACCH",
        "description": "Vue d'ensemble de l'enseignement structuré TEACCH : organisation visuelle, routines prévisibles et mise en œuvre à la maison et en milieu éducatif.",
        "contentSections": sections_3,
        "sourceUrl": TEACCH_HOME,
        "topics": ["TEACCH", "enseignement structuré", "organisation visuelle"],
        "quiz": QUIZ_COURSE_3,
        "approved": True,
        "order": 3,
    })

    return courses


def build_course_1_general() -> dict[str, Any]:
    """Course 1 — General Autism Knowledge. Aggregate from WHO, NAS, Autism Speaks."""
    # In production, scrape each URL and merge sections; here we return a template.
    return {
        "title": "General Autism Knowledge",
        "description": "Autism overview, managing autistic children in everyday scenarios (behavior, routine, sensory needs), and nutrition guidance. Content sourced from WHO caregiver training, National Autistic Society, and Autism Speaks.",
        "contentSections": [
            {"type": "text", "title": "Autism overview & key facts", "content": "", "order": 0},
            {"type": "text", "title": "Managing behavior, routine, and sensory needs", "content": "", "order": 1},
            {"type": "text", "title": "Nutrition guidance for autistic children", "content": "", "order": 2},
        ],
        "sourceUrl": "https://www.who.int/news/item/31-03-2022-who-s-training-for-caregivers-of-children-with-autism-goes-online",
        "topics": ["general autism", "caregiver skills", "WHO", "behavior", "nutrition"],
        "quiz": [],
        "approved": False,
        "order": 1,
    }


def build_course_2_pecs() -> dict[str, Any]:
    """Course 2 — PECs (Picture Exchange Communication System)."""
    return {
        "title": "PECs — Picture Exchange Communication System",
        "description": "Introduction to PECs, why it works for non-verbal or low-verbal autistic children, and practical steps to implement PECs with visual support tools.",
        "contentSections": [
            {"type": "text", "title": "Introduction to PECs and communication basics", "content": "", "order": 0},
            {"type": "text", "title": "Why PECs works for non-verbal or low-verbal children", "content": "", "order": 1},
            {"type": "text", "title": "Practical steps and visual support tools", "content": "", "order": 2},
        ],
        "sourceUrl": "https://www.autismspeaks.org/caregiver-skills-training-program",
        "topics": ["PECs", "communication", "visual support"],
        "quiz": [],
        "approved": False,
        "order": 2,
    }


def build_course_3_teacch() -> dict[str, Any]:
    """Course 3 — TEACCH Method."""
    return {
        "title": "TEACCH Method",
        "description": "Overview of TEACCH structured teaching, visual organization, predictable routines, and practical implementation at home and in educational settings.",
        "contentSections": [
            {"type": "text", "title": "Overview of TEACCH structured teaching", "content": "", "order": 0},
            {"type": "text", "title": "Visual organization and predictable routines", "content": "", "order": 1},
            {"type": "text", "title": "Implementation at home and in education", "content": "", "order": 2},
        ],
        "sourceUrl": "https://teacch.com/",
        "topics": ["TEACCH", "structured teaching", "visual organization"],
        "quiz": [],
        "approved": False,
        "order": 3,
    }


def run_scraper(urls: list[tuple[str, str | None]] | None = None) -> list[dict[str, Any]]:
    """
    Run scraper on given (url, title_override) list.
    If urls is None, returns the three built-in course templates (no live scrape).
    """
    if urls:
        courses = []
        for url, title_override in urls:
            c = scrape_url(url, title_override)
            if c:
                courses.append(c)
        return courses
    return [
        build_course_1_general(),
        build_course_2_pecs(),
        build_course_3_teacch(),
    ]


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Scrape autism training content for CogniCare")
    parser.add_argument("--url", action="append", nargs=2, metavar=("URL", "TITLE"), help="Add URL and optional title override")
    parser.add_argument("--out", default="training_courses.json", help="Output JSON file")
    parser.add_argument("--templates-only", action="store_true", help="Output only the 3 course templates (no live fetch)")
    parser.add_argument("--scrape-courses", action="store_true", help="Generate 3 courses from official sites (WHO, TEACCH, NAS, Autism Speaks); write to --out for backend seed")
    args = parser.parse_args()

    if args.scrape_courses:
        courses = build_courses_from_live_scrape()
    else:
        urls = None
        if not args.templates_only and args.url:
            urls = [(u[0], u[1] or None) for u in args.url]
        courses = run_scraper(urls)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(courses, f, indent=2, ensure_ascii=False)
    print(f"Wrote {len(courses)} course(s) to {args.out}")


if __name__ == "__main__":
    main()
