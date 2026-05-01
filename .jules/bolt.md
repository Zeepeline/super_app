
## 2025-05-14 - Pre-compiling and consolidating RegExps in LyricsService
**Learning:** Pre-compiling RegExps as `static final` members and consolidating multiple sequential `replaceAll` calls into a single call with a combined pattern (using alternation) significantly reduces overhead. In this case, it resulted in an ~11x speedup for metadata cleaning (17.33us down to 1.48us).
**Action:** Always check for repeated RegExp creation in frequently called methods and consolidate sequential string replacements where possible.
