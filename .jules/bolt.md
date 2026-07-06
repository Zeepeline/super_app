## 2026-07-06 - [Lyric Indexing & Scrolling Optimization]
**Learning:** In the `LyricsView`, the position stream updates frequently. Using a linear search ((n)$) to find the active lyric and triggering `Scrollable.ensureVisible` on every build or post-frame callback causes unnecessary UI thread work and redundant animations.
**Action:** Implement binary search ((\log n)$) for indexing and use a state variable (`_lastActiveIndex`) to gate expensive scrolling logic, ensuring it only runs when the active lyric actually changes.
