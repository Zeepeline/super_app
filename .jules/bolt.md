## 2026-05-26 - [RegExp Optimization in LyricsService]
**Learning:** Consolidating multiple sequential string `replaceAll` calls into a single pass using a combined `RegExp` pattern, combined with pre-compiling these `RegExp` instances as `static final` members, resulted in a ~5.5x speedup for metadata cleaning (4714ms down to 838ms for 1,000,000 iterations).
**Action:** Always prefer consolidated `RegExp` patterns and `static final` compilation for text processing in high-frequency service methods.
