---
name: to-stages
description: "Produce a staged plan that breaks an iterative effort into independently releasable stages, with no code or implementation details. Use for any iterative effort: new project, new feature, refactor, migration, or sustained bug-fix campaign. Triggers include \"stages document\", \"staged plan\", \"implementation stages\", \"roadmap\", \"let's break this into stages\"."
---

A staged plan describes **how we get there** for an iterative effort: it takes a stated goal and breaks the path to it into independently releasable stages, ordered by what unlocks what.

This document contains no code, no types, no interface signatures, and no implementation tactics. Those belong in the implementation, not in a planning doc.

## Inputs to confirm before writing

Confirm from the conversation, project files, or one consolidated clarifying question:

1. **The goal** — what the finished work delivers. Could come from any upstream definition (functional spec, PRD, issue ticket, README, agreed-on outcome stated in conversation). Reference it; do not restate it.
2. **Relevant context** — architecture, constraints, conventions. Just enough to anchor the stages.
3. **Guiding principles** — values the user has stated should override convenience. Only include principles the user has actually committed to. Do not invent.
4. **Explicit non-goals** — what is out of scope.

If any are missing, ask. Do not invent.

## Output location

Write to a numbered subfolder under `plans/`:

- Default: the **highest-numbered** existing subfolder (e.g. `plans/003/`).
- If no `plans/` directory exists, create `plans/000/`.
- Filename: `stages.md` inside that folder.

If it's ambiguous which folder this work belongs to, ask.

## Document structure

Sections in this order. Adapt names to the project's voice; keep the structure.

### 1. Opening paragraph

State that this is a staged plan, link to whatever upstream definition states the goal (if one exists), note that no code or implementation details appear here.

### 2. Guiding Principles

Bullet list of the user's stated values, each with one short sentence on what it means in practice. End with: when scope and a principle conflict, the principle wins. **Skip this section** if no principles have been articulated.

### 3. Context Recap

Minimum context to anchor the stages: system shape, key constraints, conventions. Just enough that a reader cold can place the stages. Link out rather than restate.

### 4. Stage 0 — Pre-work

Include only if pre-work is meaningful enough to stand as its own complete unit (e.g. test scaffolding, characterization tests, a flag/gate before a feature ramp). **Skip** if the first stage can stand on its own from day one.

### 5. Stages 1..N

Each stage is **complete, self-contained, and deployable**. A stage may lay groundwork that later stages build on, but it must always stand on its own — at the end of each stage you can ship, merge, or otherwise declare-done and walk away with something whole.

Order by what unlocks what — dependency and risk, not what's quickest to build. Common patterns (heuristics, not rules):

- A first stage that establishes the *shape* of the work (data model, interfaces, testing rhythm) by delivering the smallest complete piece that touches every concern the effort will touch. Useful when the shape is uncertain.
- Middle stages each introduce one new capability or sub-surface, building on what's already locked.
- Composition stages (mostly built from earlier work plus one new ingredient) come before stages that compound everything.
- The heaviest, most-compounded stage last — by then the underlying primitives are battle-tested.

The real constraint is: each stage is complete and independent. Use whichever ordering makes that true.

### 6. Closing Stage (optional)

Include a closing stage **only if** genuine end-of-effort work exists that cannot happen earlier — publishing a release, decommissioning an old system, flipping a default once all earlier stages have soaked, cutting over from old to new. **Skip this section entirely** if no such work exists.

Do **not** use a closing stage as a dumping ground for cleanup, polish, error-message review, or docs. Incremental quality work belongs in the stage where the code is touched — pushing it to the end concentrates risk and contradicts the whole point of staging, which is to do the right work in the smallest meaningful unit.

### 7. Beyond Scope

Bullet list of items explicitly **not** part of this plan. Catalogue them so they don't get absorbed into earlier stages.

### 8. Sequencing Summary

Short table: Stage / Delivers / Primary new capability. One row per stage.

## Stage template

Every stage entry uses this shape:

```
## Stage N — <name>

**What we deliver.** One paragraph in plain product language. What can be done after this stage that couldn't before.

**Why this stage.** Why now, not earlier or later. What does this position in the order buy us?

**In scope.** Bullet list of the discrete pieces of work, including high-level test/verification coverage.

**Out of scope.** Bullet list of adjacent things this stage does not do. Be specific about which later stage owns them.

**Done when.** Acceptance criteria as observable outcomes, not internal states.
```

## Hard rules

1. **No code.** No code blocks.
2. **No types or interface signatures.** Not even illustratively.
3. **No deep file paths.** Top-level package or module names are fine; `path/to/module/file.ts` is not.
4. **No invented principles, non-goals, or architectural decisions.** Only restate what the user has committed to.
5. **Every stage is complete, self-contained, and deployable.** A stage may include groundwork for later stages, but it must stand alone — shippable, mergeable, or otherwise declarable as done on its own merits.
6. **Stages ordered by what unlocks what**, not by what's quickest.
7. **Out-of-scope lists are honest.** Name tempting adjacent items explicitly.
