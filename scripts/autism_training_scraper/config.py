"""
Official & reputable autism training sources for scraping.
Respect robots.txt and terms of service — do not scrape restricted content.
"""

# TEACCH Autism Program
TEACCH_HOME = "https://teacch.com/"
TEACCH_TRAINING = "https://teacch.com/training/"

# Autism Speaks
AUTISM_SPEAKS_TEACCH = "https://www.autismspeaks.org/teacch"
AUTISM_SPEAKS_CST = "https://www.autismspeaks.org/caregiver-skills-training-program"

# WHO
WHO_CAREGIVER = "https://www.who.int/news/item/31-03-2022-who-s-training-for-caregivers-of-children-with-autism-goes-online"

# National Autistic Society (UK)
NAS_TRAINING = "https://www.autism.org.uk/what-we-do/autism-know-how/training"
NAS_ELEARNING = "https://www.autism.org.uk/what-we-do/autism-know-how/training/e-learning"

# NHS England
NHS_AUTISM_RESOURCES = "https://www.england.nhs.uk/learning-disabilities/about/useful-autism-resources-and-training/"

# Request headers to identify scraper and avoid blocks
HEADERS = {
    "User-Agent": "CogniCare-Training-Scraper/1.0 (Educational; autism caregiver training aggregation)",
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "en,fr",
}

# Delay between requests (seconds) to be polite
REQUEST_DELAY = 2
