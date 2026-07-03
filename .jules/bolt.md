## 2025-05-14 - [Lyrics & Library Performance Overhaul]
**Learning:** Nested list filtering ($O(M \times N)$) in `ListView.builder` is a silent performance killer for music libraries. Additionally, triggering UI animations (like `ensureVisible`) on every frame of a high-frequency stream (position updates) without checking for state changes causes significant UI thread jank.
**Action:** Always pre-group data using a `Map` ($O(N)$) before rendering complex lists. In position-driven UI components, track `_lastActiveIndex` and only trigger animations when the index actually changes.
