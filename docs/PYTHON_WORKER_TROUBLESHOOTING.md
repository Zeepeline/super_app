# 🐍 Python Worker — Panduan Troubleshooting

> Dokumen ini berisi langkah-langkah diagnosis dan perbaikan untuk masalah komunikasi Python Worker ↔ Flutter di `super_app`.

---

## Arsitektur Komunikasi

```
┌──────────────────────────────────────────────────────────┐
│                     FLUTTER (Dart)                       │
│                                                          │
│  ┌─────────────────┐     ┌────────────────────────────┐  │
│  │ PythonWorkerSvc  │     │ YoutubeDownloadService     │  │
│  │                  │     │                            │  │
│  │ • initWorker()   │     │ • downloadAndConvert()     │  │
│  │ • workerPort     │     │ • getStreamUrl()           │  │
│  │ • progressServer │     │ • progressServer (per-dl)  │  │
│  └──────┬───────────┘     └──────────┬─────────────────┘  │
│         │                            │                    │
│         │ HTTP POST                  │ HTTP POST          │
│         ▼                            ▼                    │
├─────────────────────── HTTP ──────────────────────────────┤
│         │                            │                    │
│         ▼                            ▼                    │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              PYTHON (main.py HTTPServer)             │ │
│  │                                                      │ │
│  │  Endpoints:                                          │ │
│  │  GET  /status         → {"status": "alive"}          │ │
│  │  POST /update_dart_port                              │ │
│  │  POST /search         → async, callback via port     │ │
│  │  POST /download       → async, callback via port     │ │
│  │  POST /get_url        → SYNC, returns URL langsung   │ │
│  │  POST /books/download → async, callback via port     │ │
│  └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Dua Jenis Progress Server

| Server | Pemilik | Port | Fungsi |
|--------|---------|------|--------|
| **Handshake Server** | `PythonWorkerService` | Dinamis (dari `initWorker`) | Menerima sinyal `worker_ready` + progress umum |
| **Download Progress Server** | `YoutubeDownloadService` | Dinamis (per-download) | Menerima progress download + sinyal `done`/`error` |

> ⚠️ **PENTING**: Python mengirim callback ke `port` yang diterima dari request. Pastikan port yang benar dikirim di setiap request.

---

## Checklist Diagnosis Cepat

Ketika download/fitur Python bermasalah, cek secara urut:

```
1. ✅ Apakah app.zip sudah fresh?    → ./scripts/bundle_python.sh --force
2. ✅ Apakah Python Worker start?     → Cek log "[PythonWorker] Received worker port"
3. ✅ Apakah endpoint terdaftar?      → Cek do_POST() di main.py
4. ✅ Apakah field name cocok?        → Python kirim key X, Flutter baca key X?
5. ✅ Apakah completer di-complete?   → Cek listener handle status 'done'/'error'
6. ✅ Apakah port yang benar dipakai? → Python kirim ke port mana?
```

---

## Masalah & Solusi

### 1. ❌ `Python program completed with error` + `TimeoutException`

**Gejala:**
```
flutter: Python program completed with error.
Unhandled Exception: TimeoutException after 0:02:00.000000
```

**Penyebab:** `app.zip` berisi file `.so` / `.dylib` dari macOS yang crash di iOS.

**Solusi:**
```bash
# Rebuild bundle dari awal (hapus zip lama + bersihkan binary)
./scripts/bundle_python.sh --force

# Verifikasi tidak ada file .so
unzip -l app/app.zip | grep -E '\.(so|dylib)$'
# Harus kosong!

flutter clean && flutter run
```

**Pencegahan:** Bundle script sudah otomatis jalan via VS Code `preLaunchTask`.

---

### 2. ❌ `Invalid port: null` / `FormatException`

**Gejala:**
```
flutter: Error: FormatException: Invalid port (at character 18)
flutter: http://127.0.0.1:null/download
```

**Penyebab:** Python gagal start → `_workerPort` tetap `null` → HTTP call ke `null` port.

**Solusi:**
1. Fix root cause kenapa Python gagal start (biasanya masalah #1)
2. Guard sudah ada di Dart:
```dart
if (!_workerService.isReady) {
  throw Exception('Python Worker is not ready. Cannot download.');
}
```

---

### 3. ❌ `404 Not Found` dari Python

**Gejala:**
```
DioException [bad response]: status code of 404
```

**Penyebab:** Endpoint yang dipanggil Flutter tidak terdaftar di `main.py`.

**Solusi — Cek daftar endpoint:**

| Flutter memanggil | Python `do_POST()` harus punya |
|---|---|
| `/download` | `elif self.path == '/download':` |
| `/get_url` | `elif self.path == '/get_url':` |
| `/books/download` | `elif self.path == '/books/download':` |
| `/search` | `elif self.path == '/search':` |
| `/update_dart_port` | `elif self.path == '/update_dart_port':` |

**Cara fix:**
1. Buka `python_app/main.py`
2. Tambahkan handler di `do_POST()` untuk path yang missing
3. Rebuild: `./scripts/bundle_python.sh --force`

---

### 4. ❌ Download Stuck di 15%

**Gejala:** Progress bar berhenti di 15%, tidak ada error log.

**Penyebab:** Field name mismatch — Python kirim `task_id`, Flutter baca `videoId`.

**Solusi — Pastikan field name SAMA:**

```python
# ✅ Python (main.py) — harus pakai "videoId"
self._notify_flutter(port, {
    "status": "done",
    "videoId": video_id,     # ← BUKAN "task_id"
    "message": "Download complete",
})
```

```dart
// ✅ Flutter (_handleProgressData) — baca "videoId"
final taskId = data['videoId'] as String?;
```

**Referensi field yang harus cocok:**

| Field | Python key | Flutter key |
|-------|-----------|-------------|
| ID task | `"videoId"` | `data['videoId']` |
| Status | `"status"` | `data['status']` |
| Progress | `"progress"` | `data['progress']` |
| Error msg | `"message"` | `data['message']` atau `data['error']` |

---

### 5. ❌ Download Stuck di 91%

**Gejala:** Progress bar berhenti di ~91%, tidak ada error log.

**Penyebab:** Progress listener menerima `"status": "done"` tapi **tidak menyelesaikan completer**.

**Lokasi bug:** `youtube_download_service.dart` — bagian `progressServer.listen()`

**Solusi — Listener HARUS handle done/error:**

```dart
// ✅ BENAR — handle semua status
if (status == 'done') {
  onProgress?.call('Download complete!', 0.96);
  if (!currentDownloadCompleter.isCompleted) {
    currentDownloadCompleter.complete();       // ← INI WAJIB
  }
} else if (status == 'error') {
  if (!currentDownloadCompleter.isCompleted) {
    currentDownloadCompleter.completeError(...); // ← INI WAJIB
  }
} else if (status == 'processing') {
  onProgress?.call('Finalizing file...', 0.95);
} else {
  onProgress?.call('Downloading: ...', ...);
}
```

```dart
// ❌ SALAH — done/error di-skip, completer tidak pernah selesai
if (status == 'processing') {
  onProgress?.call('Finalizing file...', 0.95);
} else if (status != 'done' && status != 'error') { // ← skip done!
  onProgress?.call('Downloading: ...', ...);
}
```

---

### 6. ❌ Python Worker Timeout tapi Akhirnya Start

**Gejala:**
```
[PythonWorker] Python Worker failed to start within 120 seconds.
[PythonWorker] Received worker port from Python: 64755   ← datang telat!
```

**Penyebab:** iOS butuh >2 menit untuk unpack zip dan start Python. Handshake datang setelah timeout.

**Solusi:**
- Timeout sudah dinaikkan ke **5 menit**
- Late handshake handler sudah dipasang:
```dart
// Di listener callback:
if (timedOut) {
  // Tetap terima handshake meskipun sudah timeout
  _isWorkerStarted = true;
  await _prefs.setInt('python_worker_port', _workerPort!);
  await _setupNewProgressServer();
}
```

---

## Workflow Pengembangan

### Setiap Kali Edit `python_app/*.py`:

```bash
# 1. Rebuild bundle
./scripts/bundle_python.sh --force

# 2. Clean dan run
flutter clean && flutter run
```

> 💡 Jika pakai VS Code, langkah 1 sudah OTOMATIS via `preLaunchTask` setiap kali F5.

### Menambah Library Python Baru:

```bash
# 1. Install ke site-packages
pip install <package> --target python_app/site-packages

# 2. WAJIB pure Python! Cek tidak ada .so:
find python_app/site-packages -name "*.so" -o -name "*.dylib"
# Harus kosong!

# 3. Rebuild bundle
./scripts/bundle_python.sh --force
```

### Menambah Endpoint Baru:

1. **Python** — Tambah handler di `do_POST()` dalam `main.py`
2. **Flutter** — Panggil endpoint via `Dio().post('http://127.0.0.1:$port/...')`
3. **Pastikan field name cocok** antara Python response dan Flutter parser
4. **Jika async** — Pastikan ada mekanisme callback + completer yang di-complete
5. **Rebuild bundle** — `./scripts/bundle_python.sh --force`

---

## File Penting

| File | Fungsi |
|------|--------|
| `python_app/main.py` | HTTP server Python, semua endpoint |
| `python_app/book_service.py` | Logic pencarian buku |
| `scripts/bundle_python.sh` | Auto-bundle dengan hash caching |
| `scripts/pre-commit.sh` | Git hook auto-bundle saat commit |
| `lib/core/services/infrastructure/python_worker_service.dart` | Lifecycle Python worker |
| `lib/core/services/download/youtube_download_service.dart` | Download YouTube + progress |
| `app/app.zip` | Bundle Python yang di-deploy ke device |
| `app/app.zip.hash` | Hash untuk smart rebuild |

---

## Quick Debug Commands

```bash
# Cek isi zip
unzip -l app/app.zip | head -20

# Cek ada binary berbahaya
unzip -l app/app.zip | grep -E '\.(so|dylib)$'

# Cek ukuran zip (harus ~6-7MB)
du -sh app/app.zip

# Force rebuild
./scripts/bundle_python.sh --force

# Test Python lokal
python3 python_app/main.py
# Lalu di terminal lain:
curl http://127.0.0.1:<PORT>/status
```
