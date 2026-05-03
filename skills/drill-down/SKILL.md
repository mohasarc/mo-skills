---
name: drill-down
description: Interview the user one question at a time, drilling down into the technical details needed to implement a chunk of work. The goal is shared understanding of what gets built, where it lives, what it touches, and what could go wrong — not to produce any document or artifact. Triggers include "drill down", "drill down on this", "grill me on the technical details", "interview me before implementation", "ask me about how this should be implemented".
---

Drill down with the user on the technical details of the work they want to implement, one question at a time. By the end of the conversation, both sides share a clear, concrete understanding of what gets built, where it lives, what it touches, and what could go wrong.

## How to drill down

- **Ask one question at a time.** Wait for the answer before moving on.
- **Explore the codebase instead of asking.** If a question can be answered by reading the code, do that — don't ask the user something the code already knows.
- **Recommend an answer with each question.** Make a concrete proposal the user can confirm, refine, or reject. Don't ask open-ended questions without a starting point.
- **Walk the dependency tree.** Earlier answers narrow later questions. Don't ask questions whose answer is already implied by what's been said.
- **Stop when there are no load-bearing unknowns left.** The interview ends when the technical picture is concrete enough to act on, not when you run out of questions to invent.

## What to drill into

Adapt to the work at hand; not every area applies to every task. Cover whichever are relevant:

- **The work itself** — its scope. What's in, what's out, what edge cases matter, what success looks like.
- **The site of change** — which files, modules, packages, or layers it touches. Where it plugs into existing structure.
- **Existing collaborators** — types, interfaces, functions, data structures, services this work integrates with. What's reused vs. changed vs. added.
- **The shape of new things** — what new types, interfaces, or modules are needed and how they relate to what's already there.
- **Behavior and contracts** — error paths, edge cases, ordering guarantees, idempotency, concurrency, anything non-obvious about how the thing should behave.
- **Testing** — how this kind of work is tested in this codebase, which test levels are in scope, what fixtures or harnesses may be needed.
- **Constraints** — performance budgets, public-API stability, files or systems off-limits, conventions to honor.
- **Risk and unknowns** — what's likely to be tricky, what might break, what the user is uncertain about.

## What this skill is not

This skill only drills down. It does not plan, scaffold, write documents, or produce artifacts. The conversation's output is shared understanding. What happens with that understanding is up to the user.
