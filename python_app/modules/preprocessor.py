"""
preprocessor.py — Text preprocessing pipeline.
normalize → expand abbreviations → remove stopwords → [chunk]
"""

import os
import re
import json
import unicodedata
import logging

import config

logger = logging.getLogger("preprocessor")

# ========== GLOBALS (loaded once) ==========
_stopwords = None
_abbreviations = None


def _load_json(path, fallback=None):
    """Safely load a JSON file with fallback."""
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception as e:
        logger.warning(f"Failed to load {path}: {e}")
    return fallback


def load_stopwords():
    """
    Load combined stopwords from data/stopwords_combined.json.
    Returns a flat set of all stopwords across all categories.
    """
    global _stopwords
    if _stopwords is not None:
        return _stopwords

    data = _load_json(config.STOPWORDS_FILE, {})
    combined = set()

    for key, words in data.items():
        if isinstance(words, list):
            combined.update(w.lower() for w in words)

    # Minimal fallback if file is empty/missing
    if not combined:
        combined = {
            "yang", "dan", "di", "ke", "dari", "untuk", "dengan", "ini",
            "itu", "pada", "adalah", "ada", "akan", "tidak", "saya", "kamu",
            "the", "a", "an", "is", "are", "was", "were", "of", "in", "to",
        }
        logger.warning("Using minimal fallback stopwords")

    _stopwords = combined
    logger.info(f"Loaded {len(_stopwords)} stopwords")
    return _stopwords


def load_abbreviations():
    """Load Indonesian abbreviation dictionary."""
    global _abbreviations
    if _abbreviations is not None:
        return _abbreviations

    _abbreviations = _load_json(config.ABBREVIATIONS_FILE, {})
    logger.info(f"Loaded {len(_abbreviations)} abbreviations")
    return _abbreviations


def normalize_text(text):
    """
    Normalize text:
    - Unicode NFKC normalization
    - Lowercase
    - Strip extra whitespace
    - Remove control characters
    """
    if not text:
        return ""

    # Unicode normalize
    text = unicodedata.normalize("NFKC", text)

    # Lowercase
    text = text.lower()

    # Remove control chars (keep newlines)
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", text)

    # Normalize whitespace (collapse multiple spaces/tabs, keep single newlines)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()


def expand_abbreviations(text, lang="id"):
    """
    Expand Indonesian abbreviations.
    'yg' → 'yang', 'dgn' → 'dengan', etc.
    Only expands whole words to avoid false positives.
    """
    if lang != "id" or not text:
        return text

    abbrevs = load_abbreviations()
    if not abbrevs:
        return text

    # Build regex pattern for whole-word matching
    # Sort by length (longest first) to avoid partial replacements
    sorted_abbrevs = sorted(abbrevs.keys(), key=len, reverse=True)
    pattern = re.compile(
        r"\b(" + "|".join(re.escape(a) for a in sorted_abbrevs) + r")\b",
        re.IGNORECASE,
    )

    def _replace(match):
        word = match.group(0).lower()
        return abbrevs.get(word, word)

    return pattern.sub(_replace, text)


def remove_stopwords(text, stopwords=None, keep_proper_nouns=True):
    """
    Remove stopwords from text.
    Optionally keeps words that start with uppercase (proper nouns).
    Note: this operates on already-lowercased text, so proper noun detection
    is best-effort based on the original word before lowering.
    """
    if not text:
        return ""

    sw = stopwords or load_stopwords()
    words = text.split()
    filtered = []

    for word in words:
        # Clean word for comparison (remove punctuation at edges)
        clean = re.sub(r"^[^\w]+|[^\w]+$", "", word)
        if clean.lower() not in sw:
            filtered.append(word)

    return " ".join(filtered)


def chunk_text(text, chunk_size=None, overlap=None):
    """
    Sliding window chunking based on token estimation (1 token ≈ 4 chars).
    Splits by sentence first, then groups by token count.

    Returns list of text chunks.
    """
    cs = chunk_size or config.CHUNK_SIZE
    ov = overlap or config.CHUNK_OVERLAP

    if not text:
        return []

    # Estimate tokens
    char_limit = cs * 4
    overlap_chars = ov * 4

    # Check if chunking is needed
    if len(text) <= char_limit:
        return [text]

    # Split by sentences
    sentences = re.split(r"(?<=[.!?。！？\n])\s+", text)

    chunks = []
    current = ""

    for sentence in sentences:
        if len(current) + len(sentence) <= char_limit:
            current = (current + " " + sentence).strip()
        else:
            if current:
                chunks.append(current)
            # Start new chunk with overlap from previous
            if chunks and overlap_chars > 0:
                prev = chunks[-1]
                overlap_text = prev[-overlap_chars:] if len(prev) > overlap_chars else prev
                current = (overlap_text + " " + sentence).strip()
            else:
                current = sentence

    if current:
        chunks.append(current)

    return chunks


def preprocess(text, lang="id", do_chunk=False):
    """
    Full preprocessing pipeline:
    1. Normalize
    2. Expand abbreviations
    3. Remove stopwords
    4. Optionally chunk

    Returns a list of processed text chunks.
    """
    if not text:
        return []

    # Safety limit
    if len(text) > config.MAX_TEXT_LENGTH:
        text = text[: config.MAX_TEXT_LENGTH]
        logger.warning("Text truncated to MAX_TEXT_LENGTH")

    # Pipeline
    text = normalize_text(text)
    text = expand_abbreviations(text, lang=lang)
    text = remove_stopwords(text)

    if do_chunk and len(text) > config.CHUNK_SIZE * 4:
        return chunk_text(text)
    else:
        return [text] if text.strip() else []
