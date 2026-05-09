---
name: architecture-review
description: Senior-engineer code review focused on architecture — loose coupling, cohesion, separation of concerns, abstraction, and reuse. Walks the branch's commits as a story, runs the build/tests, then writes a hierarchical, signal-dense review file. Triggers include "architecture review", "review this PR", "review my branch", "review the architecture of <PR>".
---

# architecture-review

Review a PR (or the current branch) the way a senior engineer would: focused on architecture, not nits. Read the commits like a story, run the code, scan for concrete architectural signals, then write a terse hierarchical review file.

## Input

- `architecture-review <pr-number-or-url>` — review a GitHub PR via `gh`.
- `architecture-review` — review the current branch against its detected base.
- `--base <ref>` — override base detection.

## Stages

Execute strictly in order. Do not skip stages.

### 1. Resolve target + base

- **PR mode**: `gh pr view <n> --json baseRefName,headRefName,number,title,url`. Use `baseRefName` as base.
- **Branch mode**: detect base by finding the local branch with the most-recent merge-base that is an ancestor of `HEAD`. Try `main`, `master`, then other local branches. If ambiguous → ask the user. `--base <ref>` overrides.
- If diff vs base is empty → exit with one line. Nothing to review.

### 2. Checkout (in-place)

- If working tree is dirty (`git status --porcelain` non-empty) → abort with one line. Do not stash.
- Capture original branch (`git rev-parse --abbrev-ref HEAD`) for later restore.
- If already on the target branch → skip checkout.
- PR mode: `gh pr checkout <n>`. Branch mode: `git checkout <branch>`.
- After all later stages succeed, restore: `git checkout <original>`. Do not bother on interruption.

### 3. Verify the build

- Discover commands from `AGENTS.md` / `CLAUDE.md` / project conventions. If nothing is documented, escalate to the user — do not guess.
- Delegate execution to a **subagent** (one per command, in parallel where independent): build, tests, typecheck, lint. Subagent returns pass/fail + short failure summary.
- **Never abort** on failure. Failures become findings:
  - Build / typecheck failure → **Blocking** finding.
  - Test failure → **Blocking** finding.
  - Lint failure → **Non-blocking** finding.

### 4. Read the story (main agent, full context)

- List commits with `git log <base>..HEAD --no-merges --pretty=format:'%h %s'`. Skip merge commits.
- For each commit, read its diff. Goal: understand the arc — what was the author solving, in what order, with what shape.
- Capture (mentally) a 2-4 sentence story for the output.

### 5. Architecture scan (main agent reads everything)

The main agent reads the full diff, every file the diff touches, and adjacent/related files needed to judge architecture. Use a **scout subagent** when you need to *find* candidates whose contents you'll later read yourself (e.g., "list every file matching `**/utils*` or with names similar to `<new symbol>`"). The scout returns paths only; the main agent reads them.

Scan for these concrete signals. Emit a finding only with a `file:line` and a one-line **why**.

**Coupling**
- Module A reaches into B's internals (not B's public surface).
- Layer crossing (e.g., renderer importing backend; CLI importing language-specific guts).
- Cyclic deps between packages.
- A module imports far more than it uses.

**Cohesion**
- One file/module mixing two unrelated responsibilities.
- Sibling files that change together commit after commit (signal they should merge, or share a seam).

**Abstraction**
- Interface owned by the implementer, not the consumer (inverted port — consumer should define what it needs).
- Implementation details leaking through public types.
- "Abstractions" with one consumer and one implementer (premature).

**Separation of concerns**
- Business logic in CLI parsing.
- I/O in pure logic.
- Validation/serialization mixed with domain.

**Reuse vs duplication**
- For each non-trivial new symbol/util/type, scout for existing equivalents (name grep + scan likely-adjacent dirs).
- **Flag duplication only inside a module/package, or across modules already coupled.** Do **not** flag duplication across independent modules — loose coupling beats DRY across module boundaries.
- Skip trivial dupes (one-line types, obvious helpers).

### 6. Classify findings

Three buckets only:

- **Blocking** — must fix before merge. Real bug, broken architecture, layer violation, missing test on critical path, build/test/typecheck failure.
- **Non-blocking** — should fix, but not gating. Cohesion smell, naming, minor abstraction issue, lint failure.
- **Question** — author has context the reviewer lacks. Genuine clarification, not rhetorical.

No "Nit". No "Praise". No filler.

### 7. Write the review file

Path: `.reviews/<pr-or-branch>.md`. **Do not overwrite.** If the file exists, write `-v2.md`, `-v3.md`, etc. Do not read prior versions.

Use the template in **Output template** below.

### 8. Restore + report

- `git checkout <original branch>` (only if checkout happened in stage 2).
- Tell the user the file path. One line. No summary of the review in chat — the file is the deliverable.

## Voice & density

The output is for a busy reader. Density beats length. Concretely:

- **Hierarchical**: top-level headers carry the full picture. Drill-down adds resolution, never new headlines. A reader scanning only headers must miss no high-value info.
- **Short sentences.** Drop articles where it doesn't hurt clarity. No throat-clearing ("This PR introduces…", "It's worth noting…").
- **Arrows, tables, and mermaid where they out-explain prose.** Don't decorate. A diagram earns its place only when it replaces words.
- Diagram types are open: sequence, state, class, flow, venn, ad-hoc illustration. Pick what helps. **Not for the story arc** — that's prose.
- Each finding: one-line headline + `file:line` + one-line why. Optional drill-down below (2-4 lines or a small diagram). Headline alone must communicate the finding.
- Empty buckets: omit the section entirely.

## Subagent boundaries

The **main agent owns judgment** and reads everything it needs to judge. Subagents only do work whose summary is the final word:

- Run build/tests/typecheck/lint, return pass/fail + failure summary.
- Scout: "find files matching X, return paths only" — main agent then reads them.
- Discover commands from `AGENTS.md` / `CLAUDE.md` / `package.json` / `Makefile`, return command list.
- Find prior PRs/commits touching these paths, return refs only.

Never delegate: reading the diff, reading source files, judging architecture, picking severity, writing the review.

## Output template

```markdown
# Review: <branch> [<PR #N>]

**Verdict:** <one line — overall architectural take>  •  Blocking: N  •  Non-blocking: M  •  Questions: K

## Story
<2-4 sentences. The arc the commits tell.>

## Health check
- Build: ✓ / ✗ <one line if ✗>
- Tests: ✓ / ✗ <one line if ✗>
- Typecheck: ✓ / ✗
- Lint: ✓ / ✗

## Blocking
### B1 — <one-line headline>
`<file:line>` — <one-line why>
<optional drill-down: 2-4 lines, table, or mermaid>

### B2 — ...

## Non-blocking
### N1 — <one-line headline>
`<file:line>` — <one-line why>

## Questions
### Q1 — <one-line headline>
<what context is missing>
```

Rules baked into the template:
- Verdict line + counts let the reader stop after one line.
- Empty sections omitted.
- No trailing "Summary" — redundant with verdict.
- No praise section.
- No restating the diff.
