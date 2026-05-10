## 2025-05-14 - Order of Operations in Regex Consolidation
**Learning:** When consolidating multiple `replaceAll` calls into a single pattern using anchors (like `$`), the order of operations matters. Removing bracketed content *after* applying a pattern with a trailing anchor can prevent matches if the anchor-targeted text is followed by brackets.
**Action:** Always verify if patterns use anchors and ensure that any noise-removal (like brackets) that might appear after the anchor is performed before the anchored replacement.
