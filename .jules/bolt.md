## 2025-05-14 - Pre-compiled and Consolidated RegExps
**Learning:** Pre-compiling RegExps as static constants significantly reduces overhead in performance-critical paths. Consolidating sequential `replaceAll` calls with alternation (`|`) in a single RegExp further reduces CPU and memory allocations during metadata cleaning.
**Action:** Always check for inline `RegExp` creation in loops or frequently called methods. Prefer `static final` declarations for RegExps and look for opportunities to combine multiple string replacement patterns.
