## 2025-05-15 - [O(N^2) Grouping Anti-pattern in LibraryPage]
**Learning:** The 'LibraryPage' used a nested 'where' filter inside a 'ListView.builder' for category grouping (Artists/Albums), leading to O(M*N) complexity. For 1,000 tracks with 100 artists, this could cause 100,000 operations during list builds.
**Action:** Always pre-group data into a Map O(N) before rendering categorized lists to ensure O(1) lookups during builder execution.
