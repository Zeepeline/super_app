## 2025-05-15 - Service-level resource optimization
**Learning:** Initializing native resources like `AudioPlayer` in a loop is a significant performance bottleneck. Similarly, repeated `RegExp` compilation and multiple sequential `replaceAll` calls on the same string cause unnecessary CPU and memory overhead.
**Action:** Always reuse expensive native instances (like `AudioPlayer`) for batch operations. Pre-compile `RegExp` as `static final` members and consolidate multiple string replacement rules into single-pass patterns using alternation.
