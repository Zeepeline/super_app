## 2026-05-08 - RegExp Optimization and Consolidation in LyricsService
**Learning:** Sequential `replaceAll` calls with dynamic `RegExp` instantiation are significantly slower than consolidated calls with pre-compiled `static final` `RegExp` members. In `LyricsService`, consolidating 19 calls into 2 reduced execution time by over 90% (from 147ms to 11ms for 10,000 iterations).
**Action:** Always profile long chains of string manipulations and consolidate regex patterns into `static final` members, especially when they are part of a library scanning or metadata processing path.
