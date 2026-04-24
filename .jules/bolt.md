## 2026-04-24 - Pre-compile Regular Expressions
**Learning:** In Flutter/Dart, instantiating `RegExp` objects inside frequently called methods (like metadata cleaning or LRC parsing) causes repeated pattern parsing and compilation overhead. Hoisting them to `static final` members significantly reduces CPU usage and GC pressure.
**Action:** Always pre-compile `RegExp` instances as `static final` class members when they are used in loops or service methods.
