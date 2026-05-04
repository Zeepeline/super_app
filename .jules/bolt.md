## 2026-05-04 - RegExp Optimization in Metadata Cleaning
**Learning:** Consolidating multiple sequential `replaceAll` calls into a single call using a combined `RegExp` with alternation, combined with hoisting `RegExp` instances to `static final` members, resulted in a ~36% performance improvement for metadata cleaning (from 141ms to 90ms for 10,000 iterations).
**Action:** Audit and consolidate string processing pipelines that use multiple `RegExp` passes into single-pass operations and ensure all `RegExp` objects are pre-compiled as static members.
