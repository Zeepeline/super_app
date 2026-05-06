#!/usr/bin/env bash

# Script to validate the python_app directory before bundling into app.zip
# This ensures that no platform-specific C-extensions (.so, .dylib, .dll) 
# or bloated files are accidentally included, which would cause crashes on iOS/Android.

PYTHON_APP_DIR="python_app"
SITE_PACKAGES_DIR="$PYTHON_APP_DIR/site-packages"

echo "🔍 Starting Python Worker Analysis..."

# 1. Check if main.py exists
if [ ! -f "$PYTHON_APP_DIR/main.py" ]; then
    echo "❌ ERROR: main.py not found in $PYTHON_APP_DIR!"
    exit 1
fi

# 2. Check for native binaries (C-extensions)
echo "🔍 Checking for platform-specific native binaries (.so, .dylib, .dll, .pyd)..."
FOUND_BINARIES=$(find "$SITE_PACKAGES_DIR" -type f \( -name "*.so" -o -name "*.dylib" -o -name "*.dll" -o -name "*.pyd" \) 2>/dev/null)

if [ -n "$FOUND_BINARIES" ]; then
    echo "❌ ERROR: Found native C-extensions in site-packages!"
    echo "These files will cause the app to crash on real iOS/Android devices because they are compiled for a specific architecture (like macOS/Windows)."
    echo "Please remove these libraries and use pure-Python alternatives."
    echo ""
    echo "List of problematic files found:"
    echo "$FOUND_BINARIES"
    exit 1
else
    echo "✅ No native binaries found. Safe for mobile distribution."
fi

# 3. Check for bloated __pycache__ directories
echo "🔍 Checking for __pycache__ folders..."
FOUND_PYCACHE=$(find "$PYTHON_APP_DIR" -type d -name "__pycache__" 2>/dev/null)

if [ -n "$FOUND_PYCACHE" ]; then
    echo "⚠️ WARNING: __pycache__ folders found. It's recommended to remove them to save space."
    # Optionally remove them automatically:
    # find "$PYTHON_APP_DIR" -type d -name "__pycache__" -exec rm -r {} +
fi

# 4. Check total size of the app directory (Warning if > 50MB)
TOTAL_SIZE_KB=$(du -sk "$PYTHON_APP_DIR" | cut -f1)
TOTAL_SIZE_MB=$((TOTAL_SIZE_KB / 1024))

echo "📊 Total size of python_app: ${TOTAL_SIZE_MB}MB"
if [ "$TOTAL_SIZE_MB" -gt 50 ]; then
    echo "⚠️ WARNING: The python_app folder is quite large (>50MB). Consider optimizing dependencies."
fi

echo "🚀 Analysis Complete. The python_app is ready to be zipped!"
exit 0
