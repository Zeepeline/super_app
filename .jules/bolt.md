## 2025-05-15 - [RegExp Pre-compilation]
**Learning:** Repeatedly compiling Regular Expressions in hot paths (like loops or frequently called utility methods) introduces unnecessary CPU and memory overhead in Dart/Flutter.
**Action:** Always extract `RegExp` instances used in loops or utility functions to `static final` class members to ensure they are compiled only once.
