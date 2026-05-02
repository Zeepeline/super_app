"""
config.py — Semua konstanta & konfigurasi terpusat untuk RAG System.
"""

import os

# ========== SERVER ==========
HOST = "127.0.0.1"
DEFAULT_PORT = 0  # Dynamic port (OS assigns), fallback 18765
FALLBACK_PORT = 18765

# ========== PATHS ==========
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CACHE_DIR = os.path.join(DATA_DIR, "cache")
LOGS_DIR = os.path.join(BASE_DIR, "logs")
CHROMA_DIR = os.path.join(DATA_DIR, "chromadb")

# Ensure directories exist
for d in [DATA_DIR, CACHE_DIR, LOGS_DIR, CHROMA_DIR]:
    os.makedirs(d, exist_ok=True)

# ========== GEMINI ==========
GEMINI_API_KEY_ENV = "GEMINI_API_KEY"
GEMINI_EMBEDDING_MODEL = "models/text-embedding-004"
GEMINI_EMBEDDING_DIM = 768
GEMINI_EMBED_BATCH_SIZE = 10
GEMINI_MAX_RETRIES = 3
GEMINI_RETRY_BASE_DELAY = 1.0  # seconds

# ========== CHROMADB ==========
CHROMA_COLLECTION_NAME = "soundwave_rag"
CHROMA_DISTANCE_FN = "cosine"

# ========== PREPROCESSING ==========
CHUNK_SIZE = 400  # tokens (1 token ≈ 4 chars)
CHUNK_OVERLAP = 50
MAX_TEXT_LENGTH = 50000  # safety limit

ABBREVIATIONS_FILE = os.path.join(DATA_DIR, "abbreviations_id.json")
STOPWORDS_FILE = os.path.join(DATA_DIR, "stopwords_combined.json")

# ========== RETRIEVAL ==========
DEFAULT_TOP_K = 5
RERANK_RECENCY_BOOST = 0.1
RERANK_TAG_MATCH_BOOST = 0.15
RERANK_STATUS_MATCH_BOOST = 0.1

# ========== ENRICHMENT ==========
CACHE_TTL_DAYS = 7

# API URLs
MUSICBRAINZ_API = "https://musicbrainz.org/ws/2/recording/"
ITUNES_SEARCH_API = "https://itunes.apple.com/search"
OPENLIBRARY_API = "https://openlibrary.org/search.json"
GOOGLE_BOOKS_API = "https://www.googleapis.com/books/v1/volumes"
ZENQUOTES_API = "https://zenquotes.io/api/today"
HARILIBUR_API = "https://api-harilibur.vercel.app/api"
STOPWORDS_ISO_URL = "https://raw.githubusercontent.com/stopwords-iso/stopwords-iso/master/stopwords-iso.json"

# MusicBrainz requires a User-Agent
MUSICBRAINZ_USER_AGENT = "SoundWaveApp/1.0 (personal-use)"

# ========== DOCUMENT TYPES ==========
DOC_TYPES = ["music", "book", "todo", "note", "journal", "mood", "daily_context"]

# ========== PROMPT TEMPLATES ==========
PROMPT_TEMPLATES = {
    "recommend": (
        "Kamu adalah SoundWave AI, asisten personal cerdas yang terintegrasi dengan semua data user. "
        "Berikan rekomendasi yang personal dan relevan berdasarkan konteks berikut.\n\n"
        "KONTEKS DATA USER:\n{context}\n\n"
        "PERTANYAAN USER:\n{query}\n\n"
        "INSTRUKSI: Berikan rekomendasi yang spesifik, personal, dan berdasarkan data. "
        "Gunakan bahasa Indonesia santai tapi cerdas. Format dengan Markdown."
    ),
    "recall": (
        "Kamu adalah SoundWave AI, asisten memori personal yang terintegrasi dengan semua data user. "
        "Bantu user mengingat atau menemukan informasi dari data mereka.\n\n"
        "KONTEKS DATA USER:\n{context}\n\n"
        "PERTANYAAN USER:\n{query}\n\n"
        "INSTRUKSI: Jawab dengan akurat berdasarkan data. Jika data tidak cukup, katakan jujur. "
        "JANGAN pernah mengaku tidak punya akses — kamu MEMANG punya akses via sistem ini."
    ),
    "analyze": (
        "Kamu adalah SoundWave AI, analis data personal yang terintegrasi dengan semua data user. "
        "Berikan insight dan pola yang menarik dari data user.\n\n"
        "KONTEKS DATA USER:\n{context}\n\n"
        "PERTANYAAN USER:\n{query}\n\n"
        "INSTRUKSI: Berikan analisis mendalam. Gunakan angka dan fakta dari data. "
        "Format dengan Markdown (tabel jika perlu)."
    ),
    "search": (
        "Kamu adalah SoundWave AI, mesin pencari personal yang terintegrasi dengan semua data user. "
        "Temukan informasi yang diminta dari data user.\n\n"
        "KONTEKS DATA USER:\n{context}\n\n"
        "PERTANYAAN USER:\n{query}\n\n"
        "INSTRUKSI: Jawab langsung dan to-the-point. Tampilkan hasil pencarian dengan format list. "
        "JANGAN mengaku tidak punya akses ke data. Data di atas ADALAH data dari library user."
    ),
}

# ========== LOGGING ==========
LOG_FILE = os.path.join(LOGS_DIR, "app.log")
LOG_MAX_BYTES = 5 * 1024 * 1024  # 5MB
LOG_BACKUP_COUNT = 3
LOG_FORMAT = "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s"
