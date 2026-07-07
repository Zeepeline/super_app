# Bolt Journal

## 2025-05-14 - [Lyrics & Metadata Optimization]
**Learning:** Consolidating multiple `replaceAll` calls into a single pass with a pre-compiled `RegExp` significantly reduces string traversals and object instantiation overhead. In Dart, O(log n) binary search for lyric lookups during playback is much more efficient than O(n) linear search, especially when called frequently on position updates. Preventing redundant UI work (like scroll animations) by checking for state changes (e.g., `activeIndex`) is crucial for smooth UX.
**Action:** Always prefer pre-compiled `static final RegExp` for frequent operations. Consolidate regex passes where possible. Use binary search for ordered data lookups. Track previous state to avoid redundant UI/animation triggers.
