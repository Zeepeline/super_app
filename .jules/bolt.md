## 2025-05-14 - Pre-compiling RegExps in Services
**Learning:** In Flutter/Dart, instantiating `RegExp` objects inside frequently called methods (like metadata cleaning) or loops (like LRC parsing) adds unnecessary overhead. Pre-compiling them as `static final` class members is a more efficient approach that avoids repeated parsing and compilation of the same patterns.
**Action:** Always check for inline `RegExp` instantiations in hot paths and move them to `static final` members.
