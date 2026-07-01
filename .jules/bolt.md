# Bolt's Journal - Performance Learnings

## 2025-05-15 - [Lyric Indexing and Metadata Optimization]
**Learning:** Replacing O(n) linear search with O(log n) binary search in high-frequency UI updates (like lyric synchronization) significantly reduces CPU overhead, especially as the list size grows. Additionally, pre-compiling RegExps and consolidating string replacement passes in metadata cleaning provides a measurable speedup (~2.6x).
**Action:** Always prefer binary search for finding items in sorted lists that are queried frequently. Move `RegExp` to `static final` members to avoid repeated compilation.

## 2025-05-15 - [Redundant Scroll Prevention]
**Learning:** In Flutter, triggering `Scrollable.ensureVisible` on every frame or position update from a stream is wasteful. Using a `StatefulWidget` to track the `_lastActiveIndex` and only triggering the scroll when it changes prevents redundant animations and UI thread work.
**Action:** Use stateful checks to debounce or throttle UI animations driven by high-frequency streams.
