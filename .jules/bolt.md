
## 2026-07-08 - [Lyrics Performance Optimization]
**Learning:** Frequent UI updates driven by streams (like playback position) can cause significant UI thread pressure if they trigger redundant animations or expensive searches (O(N) vs O(log N)).
**Action:** Always use binary search for time-sorted data indexing and implement stateful "changed" checks (e.g., _lastActiveIndex) before triggering expensive UI actions like scrolling in stream-based widgets.
