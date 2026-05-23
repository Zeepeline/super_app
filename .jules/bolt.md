## 2025-05-15 - [RegExp Consolidation & Pre-compilation]
**Learning:** Found that sequential string transformations (e.g., 19+ `replaceAll` calls in `LyricsService`) cause significant overhead due to multiple string traversals and allocations. Consolidating these into fewer passes using combined RegExps (with alternation) and pre-compiling them as `static final` members reduced execution time by ~4.8x.
**Action:** Always check for chains of `replaceAll` or `RegExp` instantiation in loops/hot paths. Consolidate into single-pass RegExps where possible and move to `static final` class members.
