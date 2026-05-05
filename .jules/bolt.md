## 2026-05-05 - [RegExp Optimization in LyricsService]
**Learning:** Consolidating multiple sequential `replaceAll` calls into a single call using a pre-compiled combined `RegExp` can significantly reduce string passes and instantiation overhead. In this case, 19 calls were reduced to 2, resulting in a ~50% speed improvement for metadata cleaning.
**Action:** Always look for chains of string replacements that can be combined into a single pattern and pre-compile `RegExp` instances as `static final` members for frequently called methods or loops.
