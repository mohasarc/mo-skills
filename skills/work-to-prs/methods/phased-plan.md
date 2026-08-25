# Phased plan method

A phased plan is a **detailed, technical** breakdown of a single unit of work into an ordered sequence of phases. It includes the types, interfaces, and snippets needed to actually build the work, decomposed further into ordered implementation steps.

The unit of work is whatever discrete chunk needs implementing — a feature, a refactor, a migration, a bug-fix campaign — described to the method in whatever form it arrives.

## Concerns

This document focuses on:

1. **High-quality, readable, testable code.** Plan the implementation to favor reuse, simplicity, and verifiability.
2. **TDD ordering.** Every phase begins by fleshing out test cases before any production code. Code follows tests, not the other way around.
3. **One concern per phase.** A phase passes the same test as a commit: if its name needs "and" to describe what it delivers, split it. Phases are the unit later grouped into PRs; a phase that bundles concerns cannot be regrouped without rewriting history.

The plan does not decide commits or PRs. The implementer turns steps into commits under the repository's commit rules; PR boundaries are decided after phases land, from the real diff.

## Inputs to gather before writing

1. **The unit of work** — the chunk being phased. What it is, what it delivers, where it ends.
2. **Relevant codebase context** — existing patterns, modules, types, and test infrastructure this work plugs into. Read the code; plan against reality, not assumptions.
3. **Constraints** — files or systems off-limits, performance budgets, public-API stability requirements, anything that bounds the implementation.
4. **Test infrastructure** — the runner, fixture conventions, and which test levels (unit / integration / e2e) are in scope.

If anything load-bearing is missing, use the best evidence-backed assumption and record it in the plan.

## Output location

Write `phased-plan.md` to the run folder the caller names.

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

**Steps.** Ordered behaviors that build the phase. Each step is one behavior: the tests that drive it plus the code that satisfies them. One line per step — a short imperative title and what it delivers. The codebase is green at the end of every step. Steps say nothing about commits; the implementer decides commit shape.

**Done when.** Observable acceptance criteria. Tests green. Specific behaviors verified.
```

## Hard rules

1. **TDD ordering is structural, not just prose.** Every phase's *Test cases* subsection precedes its *Components* subsection. Every step starts from its failing tests.
2. **Phases are self-contained.** At the end of each phase the codebase is consistent and tests pass. No "this finishes in the next phase" arrangements.
3. **One concern per phase.** If a phase's name or behavior needs "and," split it.
4. **Steps end green.** Every step leaves tests passing so any step boundary is a safe place to end a PR.
5. **Abstractions, not implementations.** The plan shows the shape of what to build — types, interfaces, signatures, declarative values — in the project's actual language and conventions. It does not contain function bodies, control flow, or algorithm implementations. Implementation happens during execution; the plan exists to direct that execution, not to do it.
6. **Reuse before invention.** Prefer existing patterns and modules in the codebase. Justify new abstractions when introducing them.
7. **Out-of-scope items are named explicitly.** Don't let adjacent work creep silently in.
8. **No invented constraints, conventions, or APIs.** Only state what's true of the codebase or what the caller has committed to.
9. **No commit or PR plan.** Commits belong to the implementer; PR boundaries belong to whoever groups finished phases.
