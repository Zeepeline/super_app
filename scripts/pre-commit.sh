#!/bin/bash

# Git pre-commit hook: memastikan app.zip up-to-date jika python_app/ berubah
# Install: cp scripts/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

PYTHON_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep "^python_app/" || true)

if [ -n "$PYTHON_FILES" ]; then
  echo "🐍 Perubahan terdeteksi di python_app/. Memperbarui app.zip..."
  ./scripts/bundle_python.sh --force

  # Stage the updated zip and hash
  git add app/app.zip app/app.zip.hash
  echo "✅ app.zip telah di-update dan di-stage otomatis."
fi
