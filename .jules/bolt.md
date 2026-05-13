## 2025-01-24 - Optimize RegExp performance and metadata cleaning
**Learning:** In Dart, creating `RegExp` instances repeatedly (especially in loops or high-frequency methods) is significantly slower than using `static final` members. Additionally, sequential `replaceAll` calls can be consolidated into fewer passes using alternation in regex, which further reduces string traversals and temporary allocations.
**Action:** Always prefer `static final` for `RegExp` patterns and look for opportunities to combine multiple string cleaning steps into single-pass regular expressions.
