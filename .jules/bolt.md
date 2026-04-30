# Bolt's Journal - Performance Learnings

## 2025-05-15 - RegExp Optimization in Dart
**Learning:** Pre-compiling `RegExp` by declaring them as `static final` members and consolidating multiple `replaceAll` calls into a single one with alternation significantly reduces execution time (measured ~5x faster in some cases). Sequential `replaceAll` on strings (which are immutable) creates multiple intermediate string objects and traverses the string multiple times.
**Action:** Always check for `RegExp` instantiation in loops or high-frequency methods. Consolidate string cleaning logic into fewer `replaceAll` calls with combined patterns.
