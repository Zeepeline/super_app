## 2025-01-24 - [Lyrics Scrolling Optimization]
**Learning:** In `LyricsView`, the `_scrollToCurrent` animation was being triggered on every position stream update (multiple times per second), even when the active lyric hadn't changed. This caused unnecessary UI thread work and potential jank. Additionally, linear search for the active lyric index is inefficient for long tracks.
**Action:** Use a stateful check (`_lastActiveIndex`) to throttle scroll animations to only occur when the active lyric actually changes. Implement binary search (O(log n)) for lyric index lookup.
