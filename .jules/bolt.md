## 2025-05-14 - Pre-compile and Consolidate RegExps
**Learning:** Sequential string `replaceAll` operations (e.g., 19+ calls in `LyricsService._cleanMetadata`) were a major bottleneck. Pre-compiling `RegExp` as `static final` and combining patterns with alternation reduced `_cleanMetadata` execution time by ~51% (from ~7.8us to ~3.9us).
**Action:** Always check for repeated `replaceAll` chains on the same string and consolidate them using combined `RegExp` patterns and `static final` instances.
