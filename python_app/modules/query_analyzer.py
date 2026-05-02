"""
query_analyzer.py — Analyze user query to determine intent, source types,
time filters, and language. Uses keyword matching only (no LLM).
"""

import re
import logging

logger = logging.getLogger("query_analyzer")

# ========== KEYWORD MAPS ==========
TYPE_KEYWORDS = {
    "music": [
        "lagu", "musik", "song", "track", "artis", "artist", "album",
        "playlist", "dengar", "listen", "putar", "play", "genre", "lirik",
        "lyrics", "nyanyi", "singer", "band", "download", "unduh",
        "green day", "chord", "melody", "beat", "ringtone",
    ],
    "book": [
        "buku", "book", "baca", "read", "novel", "penulis", "author",
        "halaman", "page", "chapter", "bab", "sinopsis", "epub", "pdf",
        "literatur", "review", "bacaan",
    ],
    "todo": [
        "todo", "task", "tugas", "jadwal", "schedule", "deadline",
        "due", "prioritas", "priority", "kerjaan", "project", "proyek",
        "to-do", "checklist", "reminder", "pengingat",
    ],
    "note": [
        "catatan", "note", "catat", "ide", "idea", "memo", "quick note",
        "tulisan",
    ],
    "journal": [
        "jurnal", "journal", "diary", "harian", "daily",
        "cerita", "story", "hari ini",
    ],
    "mood": [
        "mood", "perasaan", "feeling", "suasana", "hati", "senang",
        "sedih", "marah", "galau", "semangat", "motivasi", "stress",
        "bahagia", "happy", "sad", "anxious", "cemas",
    ],
}

INTENT_KEYWORDS = {
    "recommend": [
        "rekomendasikan", "rekomendasi", "recommend", "sarankan", "saran",
        "suggest", "cocok", "sesuai", "pas", "mirip", "similar",
        "yang bagus", "yang enak", "terbaik", "best",
    ],
    "recall": [
        "berapa", "sebutkan", "list", "daftar", "ada apa", "apa saja",
        "apa aja", "kapan", "dimana", "siapa", "gimana", "tunjukkan",
        "show", "tampilkan", "ingatkan", "remind",
    ],
    "analyze": [
        "analisis", "analyze", "pola", "pattern", "tren", "trend",
        "statistik", "stats", "insight", "rata-rata", "average",
        "perbandingan", "compare", "perkembangan", "progress",
        "produktivitas", "productivity",
    ],
    "search": [
        "cari", "search", "find", "temukan", "cek", "check",
        "ada gak", "ada ga", "punya", "ada tidak",
    ],
}

TIME_KEYWORDS = {
    "today": ["hari ini", "today", "sekarang", "now"],
    "this_week": ["minggu ini", "this week", "pekan ini"],
    "this_month": ["bulan ini", "this month"],
    "last_week": ["minggu lalu", "last week", "pekan lalu"],
    "last_month": ["bulan lalu", "last month"],
    "all_time": ["selama ini", "semua", "all", "seluruh", "semuanya"],
}


def analyze_query(query):
    """
    Analyze user query and return structured analysis.

    Returns:
    {
        "detected_types": ["music", "book"],
        "time_filter": "this_week|this_month|all_time",
        "intent": "recommend|recall|analyze|search",
        "language": "id|en|mixed",
        "keywords": ["green", "day", "lagu"],
    }
    """
    q = query.lower().strip()

    result = {
        "detected_types": _detect_types(q),
        "time_filter": _detect_time(q),
        "intent": _detect_intent(q),
        "language": _detect_language(q),
        "keywords": _extract_keywords(q),
    }

    # Default: if no type detected, search all
    if not result["detected_types"]:
        result["detected_types"] = list(TYPE_KEYWORDS.keys())

    # Default intent
    if not result["intent"]:
        result["intent"] = "search"

    return result


def _detect_types(query):
    """Detect which data types the query is about."""
    types = []
    for dtype, keywords in TYPE_KEYWORDS.items():
        for kw in keywords:
            if kw in query:
                if dtype not in types:
                    types.append(dtype)
                break
    return types


def _detect_intent(query):
    """Detect query intent."""
    best_intent = None
    best_score = 0

    for intent, keywords in INTENT_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw in query)
        if score > best_score:
            best_score = score
            best_intent = intent

    return best_intent


def _detect_time(query):
    """Detect time filter from query."""
    for time_key, keywords in TIME_KEYWORDS.items():
        for kw in keywords:
            if kw in query:
                return time_key
    return "all_time"


def _detect_language(query):
    """Simple language detection based on character analysis."""
    # Check for Indonesian-specific words
    id_markers = ["yang", "dan", "ini", "itu", "aku", "saya", "kamu", "di", "ke"]
    en_markers = ["the", "is", "are", "what", "how", "where", "which", "my"]

    id_count = sum(1 for w in id_markers if f" {w} " in f" {query} ")
    en_count = sum(1 for w in en_markers if f" {w} " in f" {query} ")

    if id_count > en_count:
        return "id"
    elif en_count > id_count:
        return "en"
    elif id_count > 0 and en_count > 0:
        return "mixed"

    # Default based on presence of non-ASCII
    return "id"


def _extract_keywords(query):
    """Extract meaningful keywords from query (remove common question words)."""
    common = {
        "berapa", "banyak", "lagu", "di", "libraryku", "saya", "ada",
        "apa", "saja", "cari", "yang", "dan", "ini", "itu", "ke",
        "dari", "untuk", "dengan", "bisa", "tolong", "mau", "minta",
        "library", "koleksi", "punya", "ku", "mu", "nya",
    }
    words = re.split(r"\s+", query)
    return [w for w in words if w not in common and len(w) > 2]
