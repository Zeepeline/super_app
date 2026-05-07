#!/bin/bash

# bundle_python.sh
# Script untuk membersihkan dan membungkus ulang Python worker.
# Menggunakan hash-based caching: hanya rebuild jika ada perubahan.
#
# Penggunaan:
#   ./scripts/bundle_python.sh          # Smart mode (skip jika tidak berubah)
#   ./scripts/bundle_python.sh --force  # Paksa rebuild meskipun tidak ada perubahan

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON_APP_DIR="$PROJECT_ROOT/python_app"
OUTPUT_ZIP="$PROJECT_ROOT/app/app.zip"
HASH_FILE="$PROJECT_ROOT/app/app.zip.hash"
FORCE=false

# Parse arguments
if [ "$1" = "--force" ]; then
  FORCE=true
fi

# ---- Step 1: Hitung hash dari semua file Python source ----
# Hanya track file .py (source code), bukan site-packages
echo "🔍 Memeriksa perubahan file Python..."

CURRENT_HASH=$(find "$PYTHON_APP_DIR" \
  -maxdepth 1 \
  -name "*.py" \
  -exec shasum -a 256 {} \; | sort | shasum -a 256 | cut -d' ' -f1)

# Juga hash isi site-packages (daftar file + ukuran, bukan konten)
SP_HASH=$(find "$PYTHON_APP_DIR/site-packages" -type f -name "*.py" \
  -exec stat -f "%N %z" {} \; 2>/dev/null | sort | shasum -a 256 | cut -d' ' -f1)

COMBINED_HASH="${CURRENT_HASH}_${SP_HASH}"

# ---- Step 2: Bandingkan dengan hash terakhir ----
if [ "$FORCE" = false ] && [ -f "$HASH_FILE" ] && [ -f "$OUTPUT_ZIP" ]; then
  SAVED_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")
  if [ "$COMBINED_HASH" = "$SAVED_HASH" ]; then
    echo "✅ Tidak ada perubahan di python_app/. app.zip sudah up-to-date."
    exit 0
  fi
fi

echo "📦 Perubahan terdeteksi! Membuat bundle baru..."

# ---- Step 3: Bersihkan file berbahaya dari source ----
echo "🧹 [1/4] Membersihkan folder Python..."

cd "$PYTHON_APP_DIR" || exit 1

# Hapus file biner native yang berbahaya untuk Mobile
find . -name "*.so" -delete 2>/dev/null || true
find . -name "*.dylib" -delete 2>/dev/null || true
find . -name "*.dll" -delete 2>/dev/null || true
find . -name "*.exe" -delete 2>/dev/null || true

# Hapus cache Python
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true

# Hapus log lama
rm -f *.log 2>/dev/null || true

# ---- Step 4: Hapus zip lama dan buat baru ----
echo "🗑️  [2/4] Menghapus app.zip lama..."
rm -f "$OUTPUT_ZIP"

echo "📦 [3/4] Membuat bundle app.zip baru..."
mkdir -p "$(dirname "$OUTPUT_ZIP")"

zip -r "$OUTPUT_ZIP" . \
  -x "*.git*" \
  -x "*.vscode*" \
  -x ".env" \
  -x "logs/*" \
  -x "*.so" \
  -x "*.dylib" \
  -x "*.dll" \
  -x "*.pyc" \
  -x "__pycache__/*" \
  -x "*.log"

cd "$PROJECT_ROOT"

# ---- Step 5: Verifikasi dan simpan hash ----
echo "🔍 [4/4] Verifikasi bundle..."
SO_COUNT=$(unzip -l "$OUTPUT_ZIP" | grep -c '\.so$' || true)
DYLIB_COUNT=$(unzip -l "$OUTPUT_ZIP" | grep -c '\.dylib$' || true)
ZIP_SIZE=$(du -sh "$OUTPUT_ZIP" | cut -f1)
FILE_COUNT=$(unzip -l "$OUTPUT_ZIP" | tail -1 | awk '{print $2}')

if [ "$SO_COUNT" -gt 0 ] || [ "$DYLIB_COUNT" -gt 0 ]; then
  echo "⚠️  PERINGATAN: Masih ada file biner native di dalam zip!"
  unzip -l "$OUTPUT_ZIP" | grep -E '\.(so|dylib)$'
  exit 1
fi

# Simpan hash baru
echo "$COMBINED_HASH" > "$HASH_FILE"

echo ""
echo "✅ Bundle berhasil!"
echo "   📏 Ukuran: $ZIP_SIZE"
echo "   📄 File: $FILE_COUNT"
echo "   🔐 Hash: ${COMBINED_HASH:0:16}..."
