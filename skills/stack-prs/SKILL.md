---
name: stack-prs
description: Slice a phased or staged plan into a stack of PRs so the human can review and merge them in parallel as later PRs land. Use when the user asks to open a PR for a phase/stage, when finishing a phase from to-implementation, or when deciding "should this be one PR or several?" — even if they don't say "stack" or "graphite" explicitly. Triggers include "PR this phase", "submit this stack", "stack these phases", "open a PR for this work", "should we bundle these into one PR".
---

# Stacking PRs from a phased plan

Phases and stages are *planning units*; PRs are *review units*. They don't have to be 1:1, but they often should be. This skill is the judgment layer for slicing a plan into a stack of PRs that the human can review and merge in parallel while later PRs are still being written. For `gt` command mechanics, defer to the `graphite` skill.

## Why stack

The human reviews **PR-1** while you build **PR-2** on top of it. Each PR is independently green, independently mergeable. When PR-1 lands on `main`, the rest restacks onto fresh `main` and keeps moving. The point is to keep the human's review queue full and your build queue full *at the same time*.

## The sizing decision

A PR contains exactly the work it needs — no padding, no cramming. If a small feature is two commits, the PR is two commits. If a phase is a single line change, that PR is one commit. Don't bundle just to hit a number.

The size of the work scales with the feature:

- **Large feature** → large stages → large phases. Each phase is usually a PR on its own; sometimes a single phase splits into two PRs if it's heavy.
- **Small feature** → one stage, a few small phases. The whole thing is often a single PR.
- **In between** → bundle adjacent phases into PRs of natural size.

**Soft heuristic for when you're actively choosing how to bundle: ~7–12 commits per PR feels right; past ~20 reviewers stop reading carefully.** This is a target when grouping, not a minimum any PR has to clear and not a hard ceiling.

When grouping phases:

- A phase that's already substantial → its own PR.
- Several tiny phases that share a theme → bundle until the PR is coherent (often into the 7–12 range, but stop sooner if there's nothing more to add).
- A phase that would blow past ~20 → split along a natural seam (test boundary, module boundary).
- Phases coupled tightly enough that splitting breaks CI (e.g. function added in one phase, first caller in the next) → bundle regardless of size.

**When in doubt, ask.** Cost of asking is one short message; cost of opening 4 PRs the user wanted as 1 is real churn. Present the slicing as options:

> "5 phases, ~14 commits total. Default would be 1 PR for the whole stack — phases are small. Or: 2 PRs split at phase 3 (8 + 6 commits). Or: 5 separate PRs. Which?"

## Workflow

For commands, see the `graphite` skill. The shape:

1. First PR branches off `main`. Subsequent PRs branch off the current top of stack — that's what makes it a stack.
2. Submit after each phase finishes green (`gt submit --no-interactive --draft`). Submitting per-phase is what unlocks parallel review.
3. Sync (`gt sync`) at the **start** of every session, before making any commits — and again after a PR merges to `main`. Graphite auto-rebases your stack on the remote whenever a downstack PR merges, so yesterday's local may already be stale. If you build commits on a stale base and *then* run `gt sync`, sync favors the up-to-date remote and silently drops your unpushed local work.
4. If you've already committed and only then notice the remote diverged: skip `gt sync`. Fetch and rebase manually — `git fetch origin <branch> && git rebase origin/<branch>` — then `gt submit`.
5. If the stack gets ~4–5 unmerged PRs deep, pause and check whether the human wants the bottom landed first.

## The `gt` vs `gh` discipline

- **Always open PRs as drafts.** Pass `--draft` to `gt submit` (so: `gt submit --no-interactive --draft`). The human marks the PR ready for review themselves when they decide it's ready — never auto-publish a non-draft PR.
- **Never use `gh pr create`.** It bypasses Graphite and breaks the stack by setting the wrong base branch. PRs are always created and pushed via `gt submit --no-interactive --draft`.
- **Use `gh` only for PR descriptions.** After `gt submit` creates a PR, use `gh pr edit` to set the title and body — `gt` doesn't manage those. (See the graphite skill for the `--body-file` pattern that avoids heredoc escaping issues.)

## Writing the PR description

The repo's `.github/PULL_REQUEST_TEMPLATE.md` defines three sections: **Summary**, **Why**, **QA**. Fill all three; don't add others — Graphite auto-posts the stack tracking, so the body focuses only on this PR's own context.

**Pyramid structure — every section, every paragraph.** Lead with the conclusion; let detail follow. The first sentence of each section is the TL;DR — what a reviewer holds if they stop reading there. Each subsequent line sharpens resolution on what was already said; nothing important arrives late. The same shape across sections: Summary alone gives the picture, +Why explains motivation, +QA confirms verification. A reviewer who stops at any point holds a complete (if lower-resolution) understanding proportional to where they stopped.

This isn't a template ritual — it's how to respect a reader's time. Reviewers self-throttle on detail; build-up structures (conclusion buried at the end) force them to read everything to find out what they're even looking at. Lead with the answer; let them choose how deep to go.

**Mermaid diagrams: only when they earn their place.** Add one when prose alone can't convey a structure efficiently — typically several entities with non-obvious relationships (a sequence across three or more components, a new module dependency graph, a state machine). The diagram *supports* the prose; it doesn't replace it. The first sentence of Summary still has to convey the change in words — a reader who scans text-only, or who can't see images, must still get the full picture.

Skip the diagram for: single-file changes, anything describable in one sentence, two-participant flows ("X calls Y" — prose is clearer), or decoration. If it doesn't reduce the prose burden, cut it. When included, place it inside Summary or Why where it supports the prose, not as a standalone "Architecture" section.

## Don't

- Don't open or push PRs the user didn't authorize. Surface "ready to submit — go?" first.
- Don't squash the stack into one PR after the fact to be tidy. If they wanted one PR they'd have said so.
