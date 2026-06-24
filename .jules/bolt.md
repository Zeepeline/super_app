## 2025-01-24 - [Lyrics search and scroll optimization]
**Learning:** Found an anti-pattern where a StatelessWidget (`LyricsView`) was managing stateful objects like `ScrollController` and a `Map` of `GlobalKey`s. This lead to inefficient rebuilds and potential memory issues. Additionally, linear search for active lyric indexing during playback (high-frequency stream updates) was a minor but avoidable bottleneck.

**Action:** Convert such components to `StatefulWidget`, implement binary search ((\log n)$) for indexing, and use a state-tracked guard (`_lastActiveIndex`) to prevent redundant UI animations.
