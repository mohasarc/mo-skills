---
name: pr-walkthrough
description: Walk through a PR — generate a hierarchical explanation with Mermaid diagrams covering background, motivation, solution approach, then flag blocking/non-blocking issues. Output a walkthrough document to docs/.
---

# PR Walkthrough & Review

Walk through a pull request — explain its background, motivation, and solution with Mermaid diagrams, then identify blocking and non-blocking issues. Output is saved as a `.md` file in `docs/`.

## Useful Commands Reference

These commands are your toolkit for gathering PR context. Use them throughout the steps below.

```bash
# Get PR number for current branch
gh pr view --json number --jq .number

# Get PR metadata (title, body, base branch, author, labels, state)
gh pr view {pr_number} --json title,body,baseRefName,headRefName,author,labels,state,url,additions,deletions,changedFiles

# Get the full diff of the PR
gh pr diff {pr_number}

# Get the list of changed files
gh pr diff {pr_number} --name-only

# Get PR description / body only
gh pr view {pr_number} --json body --jq .body

# Get all review comments (inline code comments)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --jq '[.[] | {id, path, line, body, user: .user.login}]'

# Get review-level comments (top-level reviews including approvals)
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --jq '[.[] | {id, state, body, user: .user.login}]'

# Get general issue-style comments on the PR
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --jq '[.[] | {id, body, user: .user.login}]'

# Get repo owner/name
gh repo view --json nameWithOwner --jq .nameWithOwner

# Get commit list for the PR
gh pr view {pr_number} --json commits --jq '.commits[] | "\(.oid[:7]) \(.messageHeadline)"'

# Checkout a PR branch by number (if not already on it)
gh pr checkout {pr_number}

# Get the merge base between PR branch and target
git merge-base origin/{baseRefName} origin/{headRefName}
```

---

## Step 1: Identify the PR

Determine which PR to review:

- **Current branch**: If the user says "review current PR" or "review this PR", run:
  ```bash
  gh pr view --json number,title,headRefName,baseRefName,url,body,author,additions,deletions,changedFiles,labels,state
  ```
- **PR number given**: If the user provides a PR number, run:
  ```bash
  gh pr view {pr_number} --json number,title,headRefName,baseRefName,url,body,author,additions,deletions,changedFiles,labels,state
  ```
- **PR URL given**: Extract the number from the URL and proceed as above.

If no PR exists for the current branch, tell the user and stop.

Store: `pr_number`, `title`, `baseRefName`, `headRefName`, `body`, `url`, `author`.

## Step 2: Gather Full Context

Run these in parallel:

```bash
# 1. Full diff
gh pr diff {pr_number}

# 2. Changed file list
gh pr diff {pr_number} --name-only

# 3. Commit history
gh pr view {pr_number} --json commits --jq '.commits[] | "\(.oid[:7]) \(.messageHeadline)"'

# 4. All review comments (if any exist already)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --jq '[.[] | {path, line, body, user: .user.login}]'

# 5. Review-level bodies
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --jq '[.[] | {state, body, user: .user.login}]'

# 6. Issue comments
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --jq '[.[] | {body, user: .user.login}]'
```

## Step 3: Understand the Codebase Context

Before writing the walkthrough, build understanding of what the PR touches:

1. **Read every changed file** at its current state on the PR branch — not just the diff, but the full file to understand surrounding context.
2. **Trace dependencies** — if the PR modifies a function, find its callers. If it changes a component, find where it's rendered. If it changes a type, find what consumes it.
3. **Check related files** — look at tests, configs, translations, styles that relate to the changed code but may not be in the diff.

This step is critical. You cannot write a useful walkthrough from the diff alone — you need to understand the system the PR operates within.

## Step 4: Build the Hierarchical Explanation

Structure your understanding into three layers:

### Layer 1: Background & Problem
- What area of the product does this touch?
- What was the state before this PR? What problem or gap existed?
- Is there a linked issue, ticket, or user-facing symptom?
- Who is affected (users, developers, other systems)?

### Layer 2: Motivation & Decision
- Why is this change needed now?
- What alternatives exist? Why was this approach chosen?
- What constraints shaped the solution (backward compatibility, performance, existing patterns)?

### Layer 3: Solution & Implementation
- How does the PR solve the problem?
- What are the key changes, grouped logically (not file-by-file)?
- What is the control flow / data flow after this change?
- What side effects or behavioral changes result?

## Step 5: Generate Mermaid Diagrams

Create diagrams that clarify the PR's changes. Choose diagram types based on what the PR does:

| PR Type | Diagram Types |
|---|---|
| New feature / flow | `flowchart` showing the new user or data flow |
| Refactor / restructure | `flowchart` showing before vs. after architecture |
| State changes | `stateDiagram-v2` showing state transitions |
| Multi-system interaction | `sequenceDiagram` showing component communication |
| Data model changes | `classDiagram` or `erDiagram` showing schema |
| File/module reorganization | `flowchart` showing module dependency tree |

**Rules for diagrams:**
- Minimum 1 diagram, aim for 2-3 where they add clarity.
- Every diagram must have a descriptive title as a comment above it.
- Keep diagrams focused — one concept per diagram, not everything crammed in.
- Use consistent naming that matches the actual code (function names, class names, file names).
- If the PR changes behavior, show a "before" and "after" diagram.

## Step 6: Identify Issues

Review the diff and surrounding code for issues. Classify each as:

### Blocking Issues
Issues that **must** be fixed before merge. These indicate:
- **Bugs**: Logic errors, off-by-one, null/undefined access, race conditions
- **Security**: XSS, injection, auth bypass, secret exposure, unsafe input handling
- **Data loss**: Destructive operations without safeguards, missing migrations
- **Breaking changes**: API contract violations, type mismatches, removed public interfaces without migration
- **Missing critical logic**: Unhandled error paths that will crash in production, missing validation at system boundaries

### Non-Blocking Issues
Issues worth fixing but not merge-blocking:
- **Code quality**: Naming, readability, unnecessary complexity, dead code
- **Performance**: Avoidable re-renders, missing memoization, inefficient queries (only if measurable)
- **Consistency**: Deviation from project patterns or coding standards (reference `.ai/rules/coding-standards.mdc`)
- **Testing**: Missing test coverage for new behavior, brittle test patterns
- **Suggestions**: Alternative approaches, simplifications, better abstractions

**For each issue, include:**
1. **File and line** — exact location (e.g., `src/Foo.ts:42`)
2. **What** — one-sentence description
3. **Why** — why this is a problem (not just "this is wrong")
4. **Suggested fix** — concrete code or approach, not vague advice

## Step 7: Write the Walkthrough Document

Create the file at `docs/review-pr-{pr_number}-{slug}.md` where `{slug}` is a short kebab-case summary of the PR title (max 40 chars).

Use this structure:

```markdown
# PR Walkthrough: #{pr_number} — {title}

> **Branch**: `{headRefName}` -> `{baseRefName}`
> **Author**: {author}
> **PR**: {url}
> **Date**: {YYYY-MM-DD}
> **Changed files**: {count} | **+{additions}** / **-{deletions}**

---

## 1. Background & Problem

{Layer 1 explanation — what existed before, what problem/gap this addresses.}

## 2. Motivation

{Layer 2 explanation — why this change, why now, what shaped the approach.}

## 3. Solution Overview

{Layer 3 high-level explanation — how the PR solves the problem, grouped by logical concern.}

### Architecture / Flow

{Mermaid diagram(s) here — with ```mermaid code blocks.}

## 4. Key Changes

{Walk through the significant changes grouped by concern, not file-by-file. Reference specific files and lines. Use sub-headings for distinct concerns.}

### 4.1 {Concern A}
...

### 4.2 {Concern B}
...

## 5. Blocking Issues

{List of blocking issues, or "No blocking issues found." if clean.}

### 5.1 {Short title}
- **File**: `path/to/file.ts:42`
- **What**: ...
- **Why**: ...
- **Fix**: ...

## 6. Non-Blocking Issues

{List of non-blocking issues and suggestions.}

### 6.1 {Short title}
- **File**: `path/to/file.ts:88`
- **What**: ...
- **Why**: ...
- **Suggestion**: ...

## 7. Summary

| Category | Count |
|---|---|
| Blocking issues | N |
| Non-blocking issues | N |
| Files changed | N |

**Verdict**: {APPROVE / REQUEST CHANGES / NEEDS DISCUSSION}

{1-2 sentence overall assessment.}
```

## Step 8: Report to User

After writing the file:
1. Tell the user the file path
2. Print the **Summary** section (Section 7) directly
3. If there are blocking issues, list them briefly
4. Ask if they want to discuss any specific issue in detail

## Important Rules

- **Explain first, judge second.** The walkthrough is the primary value — the review builds on that understanding.
- **Read full files, not just diffs.** Context matters. A change that looks fine in isolation may break invariants visible only in the full file.
- **Check coding standards.** Reference `.ai/rules/coding-standards.mdc` — naming, patterns, localization rules all apply.
- **Be specific.** "This could be improved" is useless. Say exactly what and how.
- **Separate opinion from fact.** Blocking issues are objective (bugs, security). Non-blocking suggestions should be clearly framed as suggestions.
- **Don't nitpick formatting** that a linter or formatter handles. Focus on logic, correctness, and design.
- **Credit what's good.** If the PR does something well (clean abstraction, good error handling, thorough tests), mention it briefly in the summary.
