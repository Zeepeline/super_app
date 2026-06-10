## 2025-05-14 - Optimized Lyrics Sync and Metadata Cleaning
**Learning:** Consolidated RegExps and binary search significantly reduce overhead in high-frequency UI updates like lyrics synchronization. Sequential string replacements can be a hidden bottleneck in metadata cleaning.
**Action:** Always prefer pre-compiled static final RegExps and (\log n)$ search for list-based UI synchronization.
