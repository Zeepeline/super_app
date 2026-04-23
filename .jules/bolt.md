## 2025-01-24 - Pre-compile RegExp instances
**Learning:** Instantiating `RegExp` objects inside frequently called methods (like metadata cleaning or LRC parsing) adds unnecessary overhead. In Dart, `RegExp` compilation is relatively expensive. Moving them to `static final` class members ensures they are compiled only once.
**Action:** Always check for `RegExp` instantiations within loops or common utility methods and move them to static constants.
