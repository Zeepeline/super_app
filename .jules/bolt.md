## 2026-06-12 - Optimized Lyrics Sync & Rendering
**Learning:** High-frequency stream updates (like playback position) cause massive UI overhead when using StreamBuilder in deep widget trees.
**Action:** Use StreamSubscription with conditional setState to limit rebuilds to only when meaningful data changes (e.g., active index).
