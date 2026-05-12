## 2025-05-15 - Regex Consolidation for Metadata Cleaning
**Learning:** Consolidating multiple sequential `replaceAll` calls (in this case, 19) into a single pass using a combined `RegExp` pattern, along with pre-compiling `RegExp` as `static final` members, provides massive performance gains. For `LyricsService._cleanMetadata`, this resulted in a ~5.8x speedup (measured over 100,000 iterations).

Crucially, when consolidating patterns, the order of removal matters. Brackets containing "junk" should be removed *after* specific metadata patterns that might use anchors like `$` or specifically target bracketed content (e.g., `(Official Video)`), to ensure those patterns match correctly before the catch-all bracket removal takes place.

**Action:** Always look for sequential string transformations using regex and consolidate them into fewer passes with pre-compiled patterns. Check for potential side effects in removal order when combining patterns.
