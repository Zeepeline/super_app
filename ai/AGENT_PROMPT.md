# MASTER PROMPT — AI Agent: Perancang RAG System untuk Super App

---

## 🎯 KONTEKS & MISI

Kamu adalah **Senior AI/ML Engineer** yang ditugaskan membangun sistem RAG (Retrieval-Augmented Generation) yang **robust, production-grade, dan lengkap** untuk sebuah personal super app berbasis Flutter.

Python backend ini berjalan di dalam Flutter menggunakan package **Serious Python** (https://pub.dev/packages/serious_python) yang me-embed Python interpreter langsung di dalam app — berjalan sebagai background thread, berkomunikasi dengan Flutter via **REST API (Flask) di localhost:18765**.

App ini bersifat **personal/private** (tidak dipublish ke App Store), berjalan di **iOS (iPhone 11 Pro, 4GB RAM) dan Desktop (macOS/Windows/Linux)**.

---

## 📱 FITUR SUPER APP (semua harus didukung RAG)

Super app ini memiliki fitur-fitur berikut. Setiap fitur menghasilkan data yang harus bisa di-index dan di-query oleh RAG:

### 1. 🎵 Music Player
- Download lagu via yt-dlp
- Koleksi musik lokal (judul, artis, genre, album, tahun)
- Playlist buatan user
- Mood/vibe tags per lagu (chill, fokus, energik, sedih, dll)
- History play & skip pattern
- Catatan pribadi per lagu ("kenapa aku suka lagu ini")
- Lyric (jika tersedia)

### 2. 📚 Baca Buku
- Koleksi buku (EPUB, PDF)
- Metadata: judul, penulis, genre, tahun terbit, sinopsis
- Status: want-to-read, reading, finished
- Progress baca (halaman/persentase)
- Highlight & annotation per halaman
- Review & rating pribadi
- Catatan bab per bab

### 3. ✅ To-do & Jadwal
- Task dengan judul, deskripsi, kategori, prioritas, due date
- Recurring tasks (harian, mingguan, bulanan)
- Sub-task support
- Status: pending, in-progress, done, cancelled
- Tags & labels
- Catatan setelah task selesai (apa yang dipelajari, dll)
- Riwayat task yang sudah selesai (sebagai "memori")

### 4. 📓 Catatan & Jurnal
- Jurnal harian (free-form text)
- Catatan terstruktur (dengan judul, tags, kategori)
- Mood tracker harian (mood score 1-10 + deskripsi)
- Quick notes (capture ide cepat)
- Voice note transcript
- Gambar dengan caption (simpan caption-nya untuk RAG)

### 5. 🤖 Second Brain / AI Chat
- User bisa tanya apapun ke AI
- AI bisa menjawab berdasarkan SEMUA data di atas secara cross-linked
- Contoh query lintas data:
  - "Rekomendasiin musik yang cocok dengan buku yang lagi aku baca"
  - "Minggu ini aku ada waktu luang, apa yang harus aku prioritaskan?"
  - "Apa pola produktivitasku berdasarkan catatan 3 bulan terakhir?"
  - "Buku apa yang temanya mirip dengan mood journalku akhir-akhir ini?"

---

## 🛠️ STACK TEKNOLOGI (WAJIB DIGUNAKAN)

```
LLM Generation  : Gemini API (gemini-2.0-flash-lite atau terbaru)
Embedding       : Gemini Embedding API (models/text-embedding-004, 768 dimensi)
Vector DB       : ChromaDB (PersistentClient, lokal di device)
Web Framework   : Flask
Entry Point     : Serious Python (main.py → Flask background thread)
Python Version  : 3.12.6 (sesuai Serious Python)
```

**Dependency constraint:**
- Hanya boleh pakai **pure Python packages** atau package yang tersedia di https://pypi.flet.dev
- TIDAK boleh pakai: PyTorch, TensorFlow, spaCy (terlalu berat untuk mobile)
- RAM budget: maksimal **200MB** total untuk seluruh Python process
- Package yang diizinkan: flask, chromadb, requests, nltk (subset), beautifulsoup4, feedparser, schedule

---

## 🌍 PENGAYAAN DATA EKSTERNAL (WAJIB DIIMPLEMENTASIKAN)

Sistem RAG harus secara **otomatis mengambil data dari sumber eksternal** untuk memperkaya konteks. Implementasikan semua sumber berikut:

### A. Stopword Lists (Multi-bahasa)
Ambil dan gabungkan stopword dari:
1. **NLTK stopwords** — English & Indonesian (via `nltk.corpus.stopwords`)
2. **GitHub: stopwords-iso** — https://raw.githubusercontent.com/stopwords-iso/stopwords-iso/master/stopwords-iso.json
   - Ambil: `id` (Indonesia), `en` (English), `ms` (Malay)
3. **Tambahan stopword domain-spesifik** yang kamu buat sendiri untuk konteks musik, buku, produktivitas:
   ```
   musik: the, a, an, feat, ft, remix, official, video, audio, lyrics, hd
   buku: chapter, page, isbn, edition, volume, pp, ibid, op, cit
   produktivitas: todo, task, item, list, note, reminder, due, date
   ```
4. Simpan hasil gabungan ke file `data/stopwords_combined.json` dan load saat startup

### B. Enrichment Data untuk Buku
Saat user menambah buku, otomatis fetch dari:
1. **Open Library API** — `https://openlibrary.org/search.json?title={title}&author={author}&limit=1`
   - Ambil: subjects, genres, number_of_pages, first_publish_year, description
2. **Google Books API** — `https://www.googleapis.com/books/v1/volumes?q={title}+{author}`
   - Ambil: description, categories, averageRating, pageCount, language
3. Gabungkan data eksternal + data user → buat "rich document" untuk di-embed

### C. Enrichment Data untuk Musik
Saat user menambah lagu, otomatis fetch dari:
1. **MusicBrainz API** — `https://musicbrainz.org/ws/2/recording/?query=recording:{title}+artist:{artist}&fmt=json`
   - Ambil: tags, genre, release year, album
2. **LastFM API (jika punya key, opsional)** atau fallback ke **iTunes Search API** (gratis, tanpa key):
   - `https://itunes.apple.com/search?term={artist}+{title}&media=music&limit=1`
   - Ambil: primaryGenreName, trackTimeMillis, collectionName
3. Fallback graceful jika API tidak tersedia (jangan crash)

### D. Enrichment Data untuk Mood/Konteks
1. Setiap malam (atau saat app dibuka pagi), fetch **motivational quotes** dari:
   - `https://zenquotes.io/api/today` — quote of the day
   - Simpan ke ChromaDB sebagai dokumen tipe `daily_context` dengan tanggal
2. Ambil **hari libur nasional Indonesia** dari:
   - `https://api-harilibur.vercel.app/api` — untuk konteks jadwal user

---

## 🧠 ARSITEKTUR RAG YANG HARUS DIBANGUN

### 1. Document Schema (Metadata ChromaDB)
Setiap dokumen di ChromaDB HARUS memiliki metadata berikut:

```python
{
    # Wajib ada di semua dokumen
    "doc_id": "uuid-v4",
    "source_type": "book|music|todo|note|journal|mood|daily_context",
    "created_at": "ISO-8601",
    "updated_at": "ISO-8601",
    "language": "id|en|mixed",
    "text_preview": "100 char pertama",

    # Field opsional per tipe (isi sesuai tipe)
    "title": "",
    "author_or_artist": "",
    "genre": "",
    "tags": "",           # comma-separated
    "status": "",
    "date_ref": "",       # tanggal relevan (due date, last read, dll)
    "rating": "",
    "mood_score": "",     # khusus mood tracker
    "enriched": "true|false",  # apakah sudah di-enrich dari API eksternal
}
```

### 2. Text Preprocessing Pipeline
Sebelum dokumen di-embed, lakukan preprocessing:

```
Raw Text
    ↓
1. Normalisasi (lowercase, strip whitespace, fix encoding)
    ↓
2. Remove stopwords (pakai combined stopwords dari langkah A)
    ↓
3. Expand abbreviations (misal: "yg" → "yang", "dgn" → "dengan")
    ↓
4. Text enrichment (tambahkan sinonim konteks jika tipe = musik/buku)
    ↓
5. Chunking (jika teks > 500 token)
    ↓
6. Embed via Gemini API
    ↓
7. Store ke ChromaDB
```

### 3. Chunking Strategy per Tipe Dokumen

| Tipe | Chunk Size | Overlap | Strategi |
|------|-----------|---------|----------|
| Catatan/Jurnal pendek (<500 token) | Tidak di-chunk | - | Simpan as-is |
| Catatan panjang (>500 token) | 400 token | 50 token | Sliding window |
| Buku (sinopsis + notes) | 300 token | 30 token | Per paragraf |
| Musik | Tidak di-chunk | - | Single document |
| Todo | Tidak di-chunk | - | Single document |
| Mood journal | Tidak di-chunk | - | Single document |

Untuk chunking, **implementasikan sendiri tanpa LangChain** (terlalu berat):
```python
def chunk_text(text: str, chunk_size: int = 400, overlap: int = 50) -> list[str]:
    # Implementasi sliding window chunking
    # Split by sentence dulu, lalu group by token count
    pass
```

### 4. Retrieval Strategy (Hybrid)
Implementasikan **dua strategi retrieval** yang bisa dikombinasikan:

**a. Semantic Search (Primary)**
- Embed query → cosine similarity di ChromaDB
- Ambil top-K (default K=5)

**b. Metadata Filter (Secondary)**
- Filter berdasarkan `source_type`, `date_ref`, `status`, `tags`
- Kombinasikan dengan semantic search menggunakan ChromaDB `where` parameter

**c. Re-ranking (Post-retrieval)**
Setelah dapat top-K hasil, lakukan simple re-ranking:
```python
def rerank(query: str, results: list, metadata_boosts: dict) -> list:
    """
    Boost score berdasarkan:
    - Recency: dokumen lebih baru dapat +0.1 boost
    - Status match: misal query "todo selesai" boost dokumen status=done
    - Tag match: jika query mengandung tag yang ada di dokumen
    """
    pass
```

### 5. Query Understanding
Sebelum retrieval, analisis query user untuk otomatis menentukan filter:

```python
def analyze_query(query: str) -> dict:
    """
    Return:
    {
        "detected_types": ["music", "book"],  # tipe data yang relevan
        "time_filter": "this_week|this_month|all_time",
        "intent": "recommend|recall|analyze|search",
        "language": "id|en"
    }
    Gunakan keyword matching sederhana, TIDAK perlu LLM untuk ini.
    """
    pass
```

### 6. Prompt Templates per Intent
Buat prompt template yang berbeda berdasarkan intent:

```python
PROMPTS = {
    "recommend": """Kamu adalah asisten personal yang merekomendasikan...""",
    "recall": """Kamu adalah asisten memori yang membantu user mengingat...""",
    "analyze": """Kamu adalah analis data pribadi yang memberikan insight...""",
    "search": """Kamu adalah mesin pencari personal yang...""",
}
```

---

## 📁 STRUKTUR FILE YANG HARUS DIBUAT

```
app/src/
├── main.py                          # Entry point Flask
├── requirements.txt
├── config.py                        # Semua konstanta & konfigurasi
├── data/
│   ├── stopwords_combined.json      # Di-generate saat setup
│   └── abbreviations_id.json        # Singkatan bahasa Indonesia
├── modules/
│   ├── __init__.py
│   ├── health.py                    # /ping endpoint
│   ├── db_manager.py                # ChromaDB singleton & utils
│   ├── gemini_client.py             # Embedding + Generation
│   ├── preprocessor.py              # Text cleaning, stopword, chunking
│   ├── enricher.py                  # Fetch data dari API eksternal
│   ├── indexer.py                   # /index/* endpoints
│   ├── rag.py                       # /rag/* endpoints
│   ├── query_analyzer.py            # Analisis intent query
│   └── scheduler.py                 # Background tasks (daily enrichment)
└── tests/
    ├── test_preprocessor.py
    ├── test_enricher.py
    └── test_rag.py
```

---

## 🔌 API ENDPOINTS LENGKAP

### Health
```
GET  /ping                          → status check
GET  /status                        → info lengkap: uptime, doc count, memory usage
```

### Indexing
```
POST /index/book                    → index buku (+ auto-enrich dari OpenLibrary/Google Books)
POST /index/music                   → index lagu (+ auto-enrich dari MusicBrainz/iTunes)
POST /index/todo                    → index todo/task
POST /index/note                    → index catatan
POST /index/journal                 → index jurnal harian
POST /index/mood                    → index mood tracker
POST /index/batch                   → bulk index (array of documents)
PUT  /index/update/<doc_id>         → update dokumen yang sudah ada
DELETE /index/delete/<doc_id>       → hapus dokumen
POST /index/reindex_all             → re-embed semua dokumen (jika model berubah)
```

### RAG
```
POST /rag/chat                      → main chat endpoint
POST /rag/search                    → pure similarity search
GET  /rag/stats                     → statistik collection
POST /rag/analyze_pattern           → analisis pola dari data user
GET  /rag/recommendations/music     → rekomendasi musik berdasarkan konteks terkini
GET  /rag/recommendations/books     → rekomendasi buku selanjutnya
GET  /rag/daily_summary             → ringkasan hari ini (todo pending + mood + dll)
```

### Setup
```
POST /setup/download_stopwords      → download & generate stopwords_combined.json
GET  /setup/status                  → cek apakah setup sudah selesai
```

---

## ⚙️ REQUIREMENTS TEKNIS WAJIB

### Error Handling
- Semua endpoint HARUS return JSON yang konsisten:
  ```json
  // Success
  {"status": "ok", "data": {...}}
  // Error
  {"status": "error", "message": "...", "code": "ERR_CODE"}
  ```
- Semua call ke API eksternal (Gemini, OpenLibrary, dll) HARUS ada try-except dengan fallback
- Jika Gemini API gagal, return error yang informatif ke Flutter (bukan crash)
- Jika ChromaDB kosong saat query, return pesan yang helpful

### Performance
- Embedding call ke Gemini harus ada **simple in-memory cache** (LRU cache, max 100 items) agar query yang sama tidak re-embed
- Enrichment data eksternal harus ada **disk cache** (simpan ke JSON di `data/cache/`) dengan TTL 7 hari
- Startup time target: Python siap dalam < 3 detik

### Keamanan
- Gemini API key HARUS diambil dari environment variable: `os.environ.get("GEMINI_API_KEY")`
- JANGAN hardcode API key apapun
- Tambahkan simple request validation (cek Content-Type, cek required fields)

### Logging
- Implementasikan logging ke file `logs/app.log` dengan rotation
- Level: INFO untuk normal flow, WARNING untuk fallback, ERROR untuk failures
- Format: `[TIMESTAMP] [LEVEL] [MODULE] message`

### Graceful Degradation
- Jika **internet tidak tersedia**: sistem tetap berjalan, hanya fitur yang butuh API eksternal yang dinonaktifkan
- Jika **Gemini API rate limited**: queue request dan retry dengan exponential backoff (max 3 retry)
- Jika **ChromaDB corrupt**: auto-backup dan recreate collection

---

## 📝 CONTOH IMPLEMENTASI YANG DIHARAPKAN

### Contoh: preprocessor.py

```python
"""
Implementasikan semua fungsi ini dengan logika yang benar dan efisien.
"""

def load_stopwords() -> set[str]:
    """Load dari data/stopwords_combined.json, fallback ke hardcoded minimal set."""
    pass

def normalize_text(text: str) -> str:
    """Lowercase, strip, fix unicode, normalize whitespace."""
    pass

def expand_abbreviations(text: str, lang: str = "id") -> str:
    """Expand singkatan: 'yg'→'yang', 'dgn'→'dengan', 'krn'→'karena', dll."""
    pass

def remove_stopwords(text: str, stopwords: set) -> str:
    """Remove stopwords tapi pertahankan proper noun (nama artis, judul buku)."""
    pass

def chunk_text(text: str, chunk_size: int = 400, overlap: int = 50) -> list[str]:
    """Sliding window chunking berbasis estimasi token (1 token ≈ 4 karakter)."""
    pass

def preprocess(text: str, lang: str = "id", do_chunk: bool = False) -> list[str]:
    """Pipeline lengkap: normalize → expand → remove stopwords → [chunk]."""
    pass
```

### Contoh: enricher.py

```python
"""
Semua fungsi enrichment harus:
1. Cek disk cache dulu sebelum hit API
2. Return None jika gagal (bukan raise exception)
3. Log warning jika API tidak tersedia
"""

def enrich_book(title: str, author: str) -> dict | None:
    """Fetch dari OpenLibrary dan Google Books, merge hasilnya."""
    pass

def enrich_music(title: str, artist: str) -> dict | None:
    """Fetch dari MusicBrainz dan iTunes Search API."""
    pass

def fetch_daily_context() -> dict | None:
    """Fetch quote harian dan hari libur, simpan ke ChromaDB."""
    pass

def _get_cache(key: str) -> dict | None:
    """Baca dari data/cache/{key}.json jika belum expired (TTL 7 hari)."""
    pass

def _set_cache(key: str, data: dict) -> None:
    """Tulis ke data/cache/{key}.json dengan timestamp."""
    pass
```

---

## 🧪 TESTING

Setelah implementasi, buat **test script** yang memverifikasi:

```python
# tests/integration_test.py
"""
Jalankan ini untuk verifikasi sistem berjalan dengan benar.
"""

def test_pipeline():
    # 1. Test download stopwords
    # 2. Test index satu buku (dengan mock enrichment)
    # 3. Test index satu lagu
    # 4. Test index satu catatan
    # 5. Test chat query yang membutuhkan cross-data
    # 6. Test similarity search
    # 7. Test rerank
    # 8. Test graceful degradation (simulasi API down)
    pass
```

---

## ✅ CHECKLIST OUTPUT YANG DIHARAPKAN

AI Agent harus menghasilkan **semua file berikut** yang siap dipakai:

- [ ] `main.py` — Flask entry point dengan proper startup sequence
- [ ] `config.py` — Semua konstanta terpusat
- [ ] `requirements.txt` — Hanya pure Python / pypi.flet.dev packages
- [ ] `data/abbreviations_id.json` — Minimal 50 singkatan bahasa Indonesia umum
- [ ] `modules/__init__.py`
- [ ] `modules/health.py`
- [ ] `modules/db_manager.py` — Dengan backup & recovery logic
- [ ] `modules/gemini_client.py` — Dengan LRU cache & retry logic
- [ ] `modules/preprocessor.py` — Pipeline lengkap dengan stopword removal
- [ ] `modules/enricher.py` — Semua API eksternal + disk cache
- [ ] `modules/indexer.py` — Semua tipe dokumen + batch indexing
- [ ] `modules/rag.py` — Hybrid retrieval + reranking + intent-based prompts
- [ ] `modules/query_analyzer.py` — Intent & filter detection
- [ ] `modules/scheduler.py` — Daily enrichment background task
- [ ] `tests/integration_test.py`
- [ ] `README.md` — Setup instructions lengkap

---

## 🚫 LARANGAN

- **DILARANG** menggunakan LangChain, LlamaIndex, atau framework RAG lain (terlalu berat)
- **DILARANG** menggunakan model embedding atau LLM lokal (torch, transformers, llama-cpp)
- **DILARANG** hardcode API key
- **DILARANG** membuat endpoint yang blocking UI (semua harus async/threaded)
- **DILARANG** skip error handling dengan alasan "development only"
- **DILARANG** mengabaikan memory budget (200MB max)

---

## 💡 CATATAN AKHIR UNTUK AI AGENT

Prioritas implementasi jika waktu terbatas:
1. **HARUS ada**: preprocessor, db_manager, gemini_client, indexer (semua tipe), rag (chat + search)
2. **SANGAT PENTING**: enricher (OpenLibrary + iTunes minimal), stopword download, disk cache
3. **PENTING**: query_analyzer, reranking, intent-based prompts
4. **NICE TO HAVE**: scheduler, daily_summary, pattern analysis

Selalu prioritaskan **robustness** (tidak crash) di atas **completeness** (semua fitur ada).
App ini dipakai sehari-hari oleh user — downtime atau crash adalah hal terburuk.

Mulailah dengan membaca seluruh prompt ini, buat rencana implementasi, lalu kerjakan file per file secara sistematis.
