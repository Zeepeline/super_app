## 2025-05-24 - Optimized Lyrics Rendering and Processing
**Learning:** Using `StreamBuilder` with high-frequency streams (like `AudioService.position`) in a complex widget tree can lead to excessive re-renders. Recalculating the active lyric index via linear search on every tick further compounds this overhead.
**Action:** For position-driven UI, prefer a manual `StreamSubscription` in a `StatefulWidget`. Update the active index using binary search and only call `setState` when the index actually changes. This decouples the UI build frequency from the stream emission frequency.
