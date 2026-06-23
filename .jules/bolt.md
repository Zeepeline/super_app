## 2025-05-14 - [LyricsView Scroll Optimization]
**Learning:** High-frequency stream updates (like playback position) can trigger redundant UI animations if not throttled by stateful checks. Even if the 'active' state doesn't change, calling `Scrollable.ensureVisible` repeatedly consumes UI thread resources and can cause jittery animations.
**Action:** Use a `StatefulWidget` to track `_lastActiveIndex` and only trigger scroll animations when the index actually changes.
