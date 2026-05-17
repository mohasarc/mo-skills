---
name: symnav-overview
description: Get a TypeScript file's symbol tree (classes, functions, methods, line numbers, signatures) in one CLI call. Use this instead of Read or grep whenever you need to know what's in a `.ts`/`.tsx` file — what it exports, where a symbol lives, what a class's methods look like. Cheaper than Read, more precise than grep. Reach for it first.
---

Run `symnav overview <path>` from inside a git workspace. Add `--json` for structured output.

Output:
- `N-M: Name` — symbol declaration (line range + qualified path like `Class::method`).
- `N text` — that symbol's source line (no colon).
- Tree glyphs show nesting; top-level entries separated by `│`.
