"""
enricher.py — External API enrichment with disk cache.
Fetches metadata from MusicBrainz, iTunes, OpenLibrary, Google Books, etc.
All functions return None on failure (never raise).
"""

import os
import json
import time
import logging
from datetime import datetime, timedelta

try:
    import requests
except ImportError:
    requests = None

import config

logger = logging.getLogger("enricher")


# ========== DISK CACHE ==========
def _get_cache(key):
    """Read from data/cache/{key}.json if not expired (TTL 7 days)."""
    path = os.path.join(config.CACHE_DIR, f"{key}.json")
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                cached = json.load(f)
            ts = cached.get("_cached_at")
            if ts:
                cached_at = datetime.fromisoformat(ts)
                if datetime.utcnow() - cached_at < timedelta(days=config.CACHE_TTL_DAYS):
                    return cached.get("data")
                else:
                    logger.info(f"Cache expired for {key}")
    except Exception as e:
        logger.warning(f"Cache read error for {key}: {e}")
    return None


def _set_cache(key, data):
    """Write to data/cache/{key}.json with timestamp."""
    path = os.path.join(config.CACHE_DIR, f"{key}.json")
    try:
        payload = {
            "_cached_at": datetime.utcnow().isoformat(),
            "data": data,
        }
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.warning(f"Cache write error for {key}: {e}")


def _safe_get(url, params=None, headers=None, timeout=10):
    """Safe HTTP GET with timeout and error handling."""
    if requests is None:
        return None
    try:
        resp = requests.get(url, params=params, headers=headers, timeout=timeout)
        if resp.status_code == 200:
            return resp.json()
        else:
            logger.warning(f"HTTP {resp.status_code} from {url}")
    except requests.exceptions.Timeout:
        logger.warning(f"Timeout fetching {url}")
    except Exception as e:
        logger.warning(f"Error fetching {url}: {e}")
    return None


# ========== MUSIC ENRICHMENT ==========
def enrich_music(title, artist):
    """
    Fetch metadata from MusicBrainz and iTunes Search API.
    Returns enriched dict or None.
    """
    cache_key = f"music_{_sanitize(title)}_{_sanitize(artist)}"
    cached = _get_cache(cache_key)
    if cached:
        return cached

    result = {}

    # 1. MusicBrainz
    mb_data = _fetch_musicbrainz(title, artist)
    if mb_data:
        result.update(mb_data)

    # 2. iTunes Search (fallback / complementary)
    itunes_data = _fetch_itunes(title, artist)
    if itunes_data:
        # Merge — iTunes data fills gaps
        for k, v in itunes_data.items():
            if k not in result or not result[k]:
                result[k] = v

    if result:
        _set_cache(cache_key, result)
        return result

    return None


def _fetch_musicbrainz(title, artist):
    """Fetch from MusicBrainz API."""
    try:
        query = f'recording:"{title}" AND artist:"{artist}"'
        data = _safe_get(
            config.MUSICBRAINZ_API,
            params={"query": query, "fmt": "json", "limit": 1},
            headers={"User-Agent": config.MUSICBRAINZ_USER_AGENT},
            timeout=8,
        )
        if not data:
            return None

        recordings = data.get("recordings", [])
        if not recordings:
            return None

        rec = recordings[0]
        tags = [t.get("name", "") for t in rec.get("tags", [])]
        releases = rec.get("releases", [])
        album = releases[0].get("title", "") if releases else ""
        year = releases[0].get("date", "")[:4] if releases else ""

        return {
            "genre": ", ".join(tags[:3]) if tags else "",
            "album_mb": album,
            "year": year,
            "mb_score": rec.get("score", 0),
        }
    except Exception as e:
        logger.warning(f"MusicBrainz error: {e}")
        return None


def _fetch_itunes(title, artist):
    """Fetch from iTunes Search API."""
    try:
        data = _safe_get(
            config.ITUNES_SEARCH_API,
            params={
                "term": f"{artist} {title}",
                "media": "music",
                "limit": 1,
            },
            timeout=8,
        )
        if not data:
            return None

        results = data.get("results", [])
        if not results:
            return None

        r = results[0]
        return {
            "genre": r.get("primaryGenreName", ""),
            "album_itunes": r.get("collectionName", ""),
            "duration_ms": r.get("trackTimeMillis", 0),
            "artwork_url": r.get("artworkUrl100", ""),
        }
    except Exception as e:
        logger.warning(f"iTunes error: {e}")
        return None


# ========== BOOK ENRICHMENT ==========
def enrich_book(title, author):
    """
    Fetch from OpenLibrary and Google Books, merge results.
    Returns enriched dict or None.
    """
    cache_key = f"book_{_sanitize(title)}_{_sanitize(author)}"
    cached = _get_cache(cache_key)
    if cached:
        return cached

    result = {}

    # 1. OpenLibrary
    ol_data = _fetch_openlibrary(title, author)
    if ol_data:
        result.update(ol_data)

    # 2. Google Books
    gb_data = _fetch_google_books(title, author)
    if gb_data:
        for k, v in gb_data.items():
            if k not in result or not result[k]:
                result[k] = v

    if result:
        _set_cache(cache_key, result)
        return result

    return None


def _fetch_openlibrary(title, author):
    """Fetch from Open Library API."""
    try:
        data = _safe_get(
            config.OPENLIBRARY_API,
            params={"title": title, "author": author, "limit": 1},
            timeout=8,
        )
        if not data:
            return None

        docs = data.get("docs", [])
        if not docs:
            return None

        doc = docs[0]
        subjects = doc.get("subject", [])[:5]

        return {
            "subjects": ", ".join(subjects) if subjects else "",
            "pages": doc.get("number_of_pages_median", 0),
            "first_publish_year": doc.get("first_publish_year", ""),
            "description_ol": (
                doc.get("first_sentence", [""])[0]
                if isinstance(doc.get("first_sentence"), list)
                else ""
            ),
        }
    except Exception as e:
        logger.warning(f"OpenLibrary error: {e}")
        return None


def _fetch_google_books(title, author):
    """Fetch from Google Books API."""
    try:
        data = _safe_get(
            config.GOOGLE_BOOKS_API,
            params={"q": f"{title}+inauthor:{author}", "maxResults": 1},
            timeout=8,
        )
        if not data:
            return None

        items = data.get("items", [])
        if not items:
            return None

        info = items[0].get("volumeInfo", {})
        return {
            "description_gb": info.get("description", "")[:300],
            "categories": ", ".join(info.get("categories", [])),
            "average_rating": info.get("averageRating", 0),
            "page_count": info.get("pageCount", 0),
            "language": info.get("language", ""),
        }
    except Exception as e:
        logger.warning(f"Google Books error: {e}")
        return None


# ========== DAILY CONTEXT ==========
def fetch_daily_context():
    """Fetch daily quote and Indonesian holidays."""
    today = datetime.utcnow().strftime("%Y-%m-%d")
    cache_key = f"daily_{today}"
    cached = _get_cache(cache_key)
    if cached:
        return cached

    result = {}

    # 1. Quote of the day
    try:
        data = _safe_get(config.ZENQUOTES_API, timeout=5)
        if data and isinstance(data, list) and data:
            result["quote"] = data[0].get("q", "")
            result["quote_author"] = data[0].get("a", "")
    except Exception as e:
        logger.warning(f"ZenQuotes error: {e}")

    # 2. Indonesian holidays
    try:
        data = _safe_get(config.HARILIBUR_API, timeout=5)
        if data and isinstance(data, list):
            # Filter for today or upcoming
            for h in data:
                hdate = h.get("holiday_date", "")
                if hdate == today:
                    result["holiday_today"] = h.get("holiday_name", "")
                    break
    except Exception as e:
        logger.warning(f"HariLibur error: {e}")

    result["date"] = today

    if result:
        _set_cache(cache_key, result)

    return result if result else None


# ========== STOPWORD DOWNLOAD ==========
def download_stopwords():
    """
    Download stopwords from GitHub stopwords-iso and merge with local file.
    Returns True on success.
    """
    try:
        data = _safe_get(config.STOPWORDS_ISO_URL, timeout=15)
        if not data:
            logger.warning("Could not download stopwords-iso")
            return False

        # Load existing file
        existing = {}
        if os.path.exists(config.STOPWORDS_FILE):
            with open(config.STOPWORDS_FILE, "r", encoding="utf-8") as f:
                existing = json.load(f)

        # Merge: keep domain-specific, update id/en/ms
        for lang_code in ["id", "en", "ms"]:
            if lang_code in data:
                existing[lang_code] = data[lang_code]

        with open(config.STOPWORDS_FILE, "w", encoding="utf-8") as f:
            json.dump(existing, f, ensure_ascii=False, indent=2)

        logger.info("Stopwords updated from stopwords-iso")
        return True

    except Exception as e:
        logger.error(f"Stopword download error: {e}")
        return False


# ========== UTILS ==========
def _sanitize(text):
    """Sanitize text for use as cache key filename."""
    import re
    s = re.sub(r"[^\w]", "_", text.lower().strip())
    return s[:50]  # limit length
