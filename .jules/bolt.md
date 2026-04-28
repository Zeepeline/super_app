## 2025-05-15 - Consolidating RegExp replaceAll Calls
**Learning:** Sequential string `replaceAll` operations with separate `RegExp` instances are significantly slower than a single `replaceAll` with a consolidated pattern using alternation. In `LyricsService._cleanMetadata`, replacing ~20 sequential calls with one reduced execution time by ~66%.
**Action:** Always look for opportunities to combine multiple text cleaning patterns into a single pre-compiled `RegExp` using the `|` (alternation) operator.

## 2025-05-15 - Pre-compiling RegExp as Static Final Members
**Learning:** Instantiating `RegExp` objects inside frequently called methods (like `parseLrc` or `_sanitizeFilename`) adds unnecessary overhead for re-compilation on every invocation.
**Action:** Move all `RegExp` instances that don't depend on local method state to `static final` class members to ensure they are compiled only once.
