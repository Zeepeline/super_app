
## 2024-05-24 - [Lyrics Synchronization & Metadata Optimization]
**Learning:** Sequential `replaceAll` calls with inline `RegExp` objects are a significant performance bottleneck in Dart, especially on hot paths like metadata cleaning. Consolidating regex into a single pass with `static final` members can yield ~2.7x-11x speedups. Additionally, linear search in UI streams (like position updates) should always be replaced with binary search (O(log n)) and stateful checks to prevent redundant UI work (like scroll animations).
**Action:** Always pre-compile RegExps used in loops or frequent service calls. Use `StatefulWidget` to persist `_lastIndex` to debounce UI side-effects driven by high-frequency streams.
