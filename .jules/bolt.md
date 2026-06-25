
## 2026-06-25 - [Lyrics Synchronization Optimization]
**Learning:** High-frequency UI updates from streams (like playback position) can cause redundant expensive operations. Moving lyric index lookup to a service using binary search and throttling scroll animations using a stateful index check significantly improves UI thread performance. Additionally, converting the view to a `StatefulWidget` ensures `GlobalKey` stability across rebuilds.
**Action:** Always throttle UI animations triggered by streams and use O(log n) lookups for synchronized content.
