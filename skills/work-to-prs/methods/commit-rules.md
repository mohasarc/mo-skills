# Commit rules

How to structure and write commits. When the repository ships its own commit rules, read those too and let them win on conflict.

## Granularity (THE MOST IMPORTANT PART)

- One logical change per commit. If the description needs "and", split
- Don't move and change at the same time: pure move commit, then edits
- Don't introduce a type and use it at the same time: type commit, then first use. Shared types with multiple consumers especially get their own preceding commit
- Don't refactor and add behavior at the same time: refactor first, behavior on top
- Foundation before consumer, leaf component before its composite
- One exported function per commit, even within the same file
- A file gaining several distinct behaviors gets one commit per behavior, even though they all touch the same file
- A function with independent concerns grows across commits: one concern per commit, each with everything that concern needs to work
- Supporting assets (styles, localization strings, config entries) land in the commit that introduces what references them, never before. Unrelated blocks split even when they share a file
- Cosmetic changes to existing elements go in their own commit, never mixed with logic
- Every commit builds
- TDD is per behavior, not per batch: commit only the failing tests for ONE behavior, then the commit that turns them green, then repeat for the next behavior. Never one huge test commit fixed across the next N commits

## Messages

- Imperative title, no type prefix (`feat:`, `fix:`, `test:`)
- Title-only by default, keep messages concise. Add a body only when the change is weird, confusing, or unusual — then state why it was done. Everything else (general rationale, root cause narrative) belongs in the PR description
- Be specific: "Rename getUserData to fetchUserProfile", not "Rename function"
