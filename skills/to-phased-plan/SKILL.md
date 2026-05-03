---
name: to-phased-plan
description: Produce a phased implementation plan — a detailed, technical, TDD-driven breakdown of a single unit of work into self-contained phases, each with test cases, abstractions (types, interfaces, signatures), and a small-commit plan governed by strict commit hygiene. Use when planning the actual implementation of a discrete chunk of work. Triggers include "phased plan", "phased implementation plan", "break this into phases", "plan the implementation of X".
---

A phased plan is a **detailed, technical** breakdown of a single unit of work into an ordered sequence of phases. It includes the types, interfaces, and snippets needed to actually build the work, decomposed further into individually reviewable commits.

The unit of work is whatever discrete chunk needs implementing — a feature, a refactor, a migration, a bug-fix campaign — described to the skill in whatever form it arrives.

## Concerns

This document focuses on:

1. **High-quality, readable, testable code.** Plan the implementation to favor reuse, simplicity, and verifiability.
2. **TDD ordering.** Every phase begins by fleshing out test cases before any production code. Code follows tests, not the other way around.
3. **Minimal, reviewable commits.** Each commit does **one thing** and is easy to review on its own. A commit may span a whole phase, a single step within a phase, or a handful of steps — whatever keeps it minimal.

## Commit hygiene rules

Every commit in the plan must satisfy these. They exist because every violation makes a diff harder to review:

- **Don't move and change at the same time.** Move a file, function, or block in one commit; change its contents in the next. Reviewers can verify a pure move at a glance; a move-with-edits forces them to reconstruct what changed inside the move.
- **Don't introduce a type and use it at the same time.** Add the type definition in one commit; introduce its first use in the next. The reader sees the type's shape on its own before having to follow it to a callsite.
- **Don't refactor and add new functionality at the same time.** Refactor surrounding code first; add new behavior on top. Mixing them obscures whether a behavior change rode in on the refactor.
- **One logical change per commit.** If a commit description needs the word "and" to capture what it does, split it.

## Inputs to gather before writing

1. **The unit of work** — the chunk being phased. What it is, what it delivers, where it ends.
2. **Relevant codebase context** — existing patterns, modules, types, and test infrastructure this work plugs into. Read the code; plan against reality, not assumptions.
3. **Constraints** — files or systems off-limits, performance budgets, public-API stability requirements, anything that bounds the implementation.
4. **Test infrastructure** — the runner, fixture conventions, and which test levels (unit / integration / e2e) are in scope.

If anything load-bearing is missing, ask.

## Output location

Write to a descriptively-named subfolder under `plans/`:

- Default: `plans/<highest-numbered>/<descriptive-slug>/phased-plan.md`, where the slug names the unit of work.
- If no `plans/` directory exists, create `plans/000/<descriptive-slug>/phased-plan.md`.
- If it's ambiguous which folder this belongs to, ask.

## Document structure

### 1. Header

Title and one-sentence description of the unit being phased. Link to its source (if one exists in the project).

### 2. Goal

What this plan delivers when all phases are complete. State the observable outcome — what works after that didn't work before. One paragraph.

### 3. Context

Just enough about the surrounding codebase to read the rest cold: which modules are touched, which types and interfaces are reused, where the new code plugs in, what tests already exist that this work extends. Reference real symbols and files. Tight.

### 4. Phases

One section per phase, ordered. Each phase is self-contained — at the end of a phase the codebase is in a consistent state with passing tests, and is observably more capable than before. Use the phase template below.

### 5. Out of scope

Adjacent work this plan does **not** do. Point at the future work that owns each item.

## Phase template

Every phase entry uses this shape:

```
## Phase N — <name>

**Behavior delivered.** What works after this phase that didn't work before, in user/caller-observable terms.

**Test cases.** The tests that drive this phase, written *first*. For each test:
- What is being tested (the scenario or contract).
- The assertion(s).
- The level (unit / integration / e2e).
- Any fixture, stub, or harness work the test requires.

**Components.** The *shape* of what this phase introduces or modifies — abstractions and contracts, not implementations. Include:
- Full type and interface definitions.
- Full function and method signatures.
- Constants, config shapes, and declarative values when they form part of the contract.

Do **not** include function bodies, control flow, or algorithm implementations. If a non-obvious algorithm needs to be communicated, describe it in prose — *what* it does, not *how* — so the implementer writes the code during execution.

**Commit plan.** Ordered list of commits implementing this phase. For each commit:
- A short imperative commit-message-style title.
- One sentence on what changes and why.
- A note on which hygiene rule it preserves (e.g. "type-only, no callsites yet"; "pure move, no edits"; "refactor only, no behavior change").

**Done when.** Observable acceptance criteria. Tests green. Specific behaviors verified.
```

## Hard rules

1. **TDD ordering is structural, not just prose.** Every phase's *Test cases* subsection precedes its *Components* subsection. Every commit plan begins with at least one commit that adds (failing) tests before any commit that adds production code.
2. **Phases are self-contained.** At the end of each phase the codebase is consistent and tests pass. No "this finishes in the next phase" arrangements.
3. **Commits obey the hygiene rules above.** If a commit's description needs an "and," split it.
4. **Abstractions, not implementations.** The plan shows the shape of what to build — types, interfaces, signatures, declarative values — in the project's actual language and conventions. It does not contain function bodies, control flow, or algorithm implementations. Implementation happens during execution; the plan exists to direct that execution, not to do it.
5. **Reuse before invention.** Prefer existing patterns and modules in the codebase. Justify new abstractions when introducing them.
6. **Out-of-scope items are named explicitly.** Don't let adjacent work creep silently in.
7. **No invented constraints, conventions, or APIs.** Only state what's true of the codebase or what the user has committed to.
