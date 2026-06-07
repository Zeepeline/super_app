## 2025-05-15 - Optimizing Lyrics Synchronization and UI Rebuilds

**Learning:** In Flutter applications using GetX, placing high-frequency stream listeners (like `positionStream`) inside a widget's `build` method via `StreamBuilder` can cause excessive rebuilds (60fps) even when the actual derived state (like the active lyric index) hasn't changed. Combining this with $O(n)$ searches in the build loop significantly impacts UI performance.

**Action:** Move high-frequency stream logic to the controller and expose a derived reactive state (e.g., `activeIndex`). Use GetX workers (`ever`) or specific reactive listeners in the widget to trigger UI side effects (like scrolling) only when the derived state changes, and use binary search for sorted time-based data.
