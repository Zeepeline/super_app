## 2025-05-22 - Pre-compiled and Consolidated RegExps
**Learning:** High-traffic string operations (like metadata cleaning and LRC parsing) suffer from repeated RegExp compilation and multiple full-string passes. Consolidating 19 sequential replaceAll calls into 2 reduced execution time by ~8x.
**Action:** Always pre-compile RegExps as static final members and consolidate sequential string transformations into single patterns when possible.
