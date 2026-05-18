
## 2025-05-14 - [RegExp Pre-compilation and Consolidation]
**Learning:** Consolidating sequential string `replaceAll` calls into a single pass using a pre-compiled `RegExp` with alternation (`|`) significantly reduces execution time by avoiding multiple string traversals and memory allocations. Pre-compiling RegExps as `static final` class members avoids the overhead of repeated compilation in hot paths like metadata cleaning or file scanning loops.
**Action:** Always prefer pre-compiled `static final` RegExp members. In text-heavy cleaning tasks, look for opportunities to combine multiple patterns into a single pass.
