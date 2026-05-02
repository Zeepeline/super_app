"""
gemini_client.py — Gemini Embedding & Generation API client.
Features: LRU cache, retry with exponential backoff, batch embedding.
"""

import os
import time
import hashlib
import logging
from collections import OrderedDict

try:
    import requests
except ImportError:
    requests = None

import config

logger = logging.getLogger("gemini_client")

# ========== LRU CACHE ==========
_embed_cache = OrderedDict()
_CACHE_MAX = 100


def _cache_key(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest()


def _cache_get(text):
    key = _cache_key(text)
    if key in _embed_cache:
        _embed_cache.move_to_end(key)
        return _embed_cache[key]
    return None


def _cache_set(text, embedding):
    key = _cache_key(text)
    _embed_cache[key] = embedding
    if len(_embed_cache) > _CACHE_MAX:
        _embed_cache.popitem(last=False)


# ========== API KEY ==========
def _get_api_key():
    key = os.environ.get(config.GEMINI_API_KEY_ENV)
    if not key:
        logger.warning("GEMINI_API_KEY not set in environment")
    return key


# ========== EMBEDDING ==========
def embed_text(text):
    """
    Embed a single text using Gemini Embedding API.
    Returns a list of floats (768 dimensions) or None on failure.
    """
    if not text or not text.strip():
        return None

    # Check cache
    cached = _cache_get(text)
    if cached is not None:
        return cached

    api_key = _get_api_key()
    if not api_key:
        return None

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/"
        f"{config.GEMINI_EMBEDDING_MODEL}:embedContent?key={api_key}"
    )

    payload = {
        "model": config.GEMINI_EMBEDDING_MODEL,
        "content": {"parts": [{"text": text}]},
    }

    for attempt in range(config.GEMINI_MAX_RETRIES):
        try:
            resp = requests.post(url, json=payload, timeout=15)

            if resp.status_code == 200:
                data = resp.json()
                embedding = data.get("embedding", {}).get("values")
                if embedding:
                    _cache_set(text, embedding)
                    return embedding
                else:
                    logger.warning(f"No embedding in response: {data}")
                    return None

            elif resp.status_code == 429:
                # Rate limited — backoff
                delay = config.GEMINI_RETRY_BASE_DELAY * (2 ** attempt)
                logger.warning(f"Rate limited, retrying in {delay}s...")
                time.sleep(delay)
                continue

            else:
                logger.error(
                    f"Embedding API error {resp.status_code}: "
                    f"{resp.text[:200]}"
                )
                return None

        except requests.exceptions.Timeout:
            logger.warning(f"Embedding timeout (attempt {attempt + 1})")
            time.sleep(config.GEMINI_RETRY_BASE_DELAY)
        except Exception as e:
            logger.error(f"Embedding error: {e}")
            return None

    logger.error("Embedding failed after all retries")
    return None


def embed_batch(texts):
    """
    Embed multiple texts. Returns a list of embeddings (or None per failed item).
    Uses individual calls (Gemini batch embed has different API).
    """
    results = []
    for text in texts:
        emb = embed_text(text)
        results.append(emb)
        # Small delay to avoid rate limits
        if len(texts) > 5:
            time.sleep(0.1)
    return results


def is_available():
    """Check if Gemini API is reachable and key is set."""
    api_key = _get_api_key()
    if not api_key:
        return False
    try:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/"
            f"models?key={api_key}"
        )
        resp = requests.get(url, timeout=5)
        return resp.status_code == 200
    except Exception:
        return False
