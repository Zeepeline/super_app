## 2026-05-02 - Pre-compile and Consolidate RegExps
**Learning:** In Dart, repeatedly instantiating `RegExp` in a hot loop or frequently called method (like metadata cleaning) adds significant overhead. Consolidating multiple sequential `replaceAll` calls into a single call using alternation (`|`) and pre-compiling patterns as `static final` members can yield massive performance gains.
**Action:** Always check for `RegExp` instantiation in loops or common utility methods and move them to `static final` constants. Consolidate sequential string manipulations into fewer passes.
