---
name: to-functional-spec
description: "Produce a functional spec — a document that defines what a system does and how it behaves from the user's perspective, with no source code, types, or technology choices. Applies to any kind of system: CLI, API, library, web app, mobile app, embedded device, internal service, etc. Triggers include \"functional spec\", \"behavior spec\", \"product spec\", \"what should X do\"."
---

A functional spec describes **what** the system does and **how it behaves from the user's perspective**. It defines product behavior only — no source code, no types, no interface signatures, no technology choices. Implementation lives elsewhere.

The spec is the source of truth for behavior.

This skill applies to any system regardless of its surface — CLI, HTTP API, library, web app, mobile app, embedded device, internal service. The structure below is universal; section names and examples should be adapted to the system at hand.

## Inputs to confirm before writing

Confirm from the conversation, project files, or one consolidated clarifying question:

1. **What the system is** — what it does, who it's for, what it replaces or competes with, what it explicitly is not.
2. **The primary consumer** — the first-class user. Their default experience.
3. **Invariants** — guarantees the system must always uphold.
4. **Scope** — what's in this version and what's explicitly excluded.
5. **Features** — the discrete user-visible capabilities the spec needs to cover (commands, endpoints, screens, methods, actions — whatever applies).

If any are missing, ask. Do not invent.

## Output location

Write to a numbered subfolder under `plans/`:

- Default: the **highest-numbered** existing subfolder.
- If no `plans/` directory exists, create `plans/000/`.
- Filename: `<project-or-feature>-functional-spec.md`, or `functional-spec.md` if there's no obvious project/feature name.

If it's ambiguous which folder this belongs to, ask.

## Document structure

Sections in this order. Include only those that apply — adapt names to the system. For example, the "Output / Response Format" section might be "Response Schema" for an API, "Visual Grammar" for a UI, "Return Contract" for a library, or omitted entirely if the system has no observable output beyond state changes.

### 1. Goal

One paragraph: what the system does, who it's for, what it replaces or competes with, what it explicitly is not. End with a sentence stating the spec defines product behavior only and avoids implementation choices.

### 2. Primary User

The first-class consumer. State their default experience and what alternative experiences exist behind explicit opt-in.

### 3. Core Guarantees

Invariants the system always upholds. Each guarantee is its own subsection containing:

- A plain statement of the rule.
- A precise, quotable restatement (a "functional rule"), often shown in a `text` code block so it can be lifted verbatim into tests or other documents.
- Examples of correct behavior, including correct **failure** behavior — what the system says or does when it can't satisfy a request.
- Explicit no-override clauses ("There is no stale-data override.") whenever the guarantee can't be relaxed by a flag, parameter, or special call.

### 4. Scope

What's included in this version; what's explicitly excluded. Both lists are flat and complete. The exclusion list is what prevents silent scope creep later.

### 5. Interaction Model

How users address the system. Covers whatever form interaction takes — command-line arguments, HTTP routes, library function calls, UI navigation, voice commands, message payloads. Define:

- The conventions for what the system accepts.
- What is **not** accepted, stated explicitly when a reader might assume otherwise.
- The canonical shape of any identifier or addressable concept, with examples.

### 6. Output / Response Format

The shape of what the system produces in response to interactions. The form depends on the system: text layout for a CLI, response bodies and status codes for an API, visual hierarchy for a UI, return values and side effects for a library. When the format itself is a contract, state it precisely and show examples that reflect what users literally observe.

### 7. Cross-cutting Concerns

Anything that applies across all features rather than to one in particular. Common examples: pagination, error reporting, throttling, idempotency, sort order, determinism, concurrency, accessibility, internationalization. State defaults as bare concrete values.

### 8. Per-feature Sections

One section per discrete user-visible feature (command, endpoint, screen, method, action — whatever applies). For each:

- **Purpose** — a one-line plain-language statement.
- **What it produces / does not produce** — explicit positive **and** negative space.
- **Examples** — concrete, faithful illustrations of what users experience.
- **Defaults** — concrete values for any parameter with a default.
- **Edge cases** — empty results, ambiguity, errors, boundary conditions.

### 9. Summary

At-a-glance recap of all features, one short description each.

## Hard rules

1. **No source code, no types, no interface signatures.** Code blocks are reserved for:
   - Examples of user-side interaction (invocations, requests, gestures, payloads).
   - Examples of system response (output, return values, payloads, screen states).
   - Quotable rules and defaults shown as bare values.
2. **No technology choices.** Don't name the database, framework, library, language, or platform unless the choice is itself a user-visible constraint.
3. **Behavior is described from the user's perspective.** What the user observes and does, not how the system computes it.
4. **Negative space is explicit.** State what the system does *not* do whenever readers might assume otherwise.
5. **Defaults are stated as bare concrete values**, not "reasonable defaults."
6. **No-override clauses are called out.** When a guarantee can't be relaxed, say so.
7. **Examples reflect what users actually observe.** When the form of an interaction or response is a contract, examples must show it precisely.
8. **Excluded scope is named.** Out-of-scope items appear in the scope section, not in implicit gaps.
