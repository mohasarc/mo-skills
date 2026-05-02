---
name: phased-implementation-plan
description: Break down implementation plans into detailed, self-contained phased plans where each phase is a single focused commit. Use when the user asks to create a phased plan, break down a task, or plan a PR with multiple commits.
---

# Phased Implementation Plan

## Instructions

When asked to create a phased implementation plan, generate a detailed Markdown file containing a sequence of logically self-contained phases. Each phase represents a **single git commit**.

Follow these core principles to ensure the PR commits read like a story and are polite to the reviewer:

1. **Single Operation per Commit**: Each commit must focus on exactly one thing (e.g., add a new feature, modify a specific part, refactor). Never combine multiple unrelated changes.
2. **Rule of Thumb**: If the changes cannot be described in a single commit message sentence, they must be broken down into smaller commits. The use of "and" in the commit message is a sign it should be broken down.
3. **Introduce, Use, Remove**:
    - Introduce a new concept/component, expose it, add its tests in one commit.
    - Use it in a separate commit.
    - Optionally remove the old concept/component in a separate commit.
4. **Always Compile**: Each phase must describe changes that will compile successfully. For example, if an interface is modified, all of its usages must be updated in the exact same phase.
5. **Logical Flow**: Commits should flow naturally from one to the next, building up the feature step-by-step like a story. Avoid front-loading all additions (e.g., creating 5 new components in 5 consecutive commits before using any of them). Instead, interleave additions, usages, and cleanups to maintain a clear, understandable progression.
6. **Tests as phase validation**: Treat each phase as done when behavior is covered by tests. Plan to add or update tests at the end of the phase (same commit) so validation is not deferred to a later “test-only” phase unless that is the only practical option.
7. **Cleanup and refactors**: these must be in seperate commits, don't mix implementation and refactor. if you have to move files, dedicate a single commit to do so. if you need to rename a variable, dedicate a single commit for that.

## Output Format

Write the detailed plan to a new Markdown file (e.g., `docs/phased-plan-<feature>.md`).

```markdown
# Phased Implementation Plan: [Feature Name]

Overal feature description, purpose, goal etc.. (make sure it's complete and self-contained)

## Phase 1: [Short, single-sentence commit message]

-   **Goal**: [What this phase achieves]
-   **Steps**:
    how to implement this phase: include (when necessary) code snipts, type definitions, files to change etc.. (it's meant as a lightweight guide)
-   **Validation**: [How to ensure it works—include adding or updating tests in this phase where applicable, plus compile/build and any manual checks]

## Phase 2: [Short, single-sentence commit message]

...
```
