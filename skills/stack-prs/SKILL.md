---
name: stack-prs
description: Slice a phased or staged plan into a stack of PRs so the human can review and merge them in parallel as later PRs land. Use when the user asks to open a PR for a phase/stage, when finishing a phase from to-implementation, or when deciding "should this be one PR or several?" — even if they don't say "stack" explicitly. Triggers include "PR this phase", "submit this stack", "stack these phases", "open a PR for this work", "should we bundle these into one PR".
---

# Stacking PRs from a phased plan

Phases and stages are *planning units*; PRs are *review units*. They don't have to be 1:1, but they often should be. This skill is the judgment layer for slicing a plan into a stack of PRs that the human can review and merge in parallel while later PRs are still being written. For command mechanics, defer to the stacking tool's docs.

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

Use the stacking tool the repo's rules name, and its docs for commands. No tool named: use `stack-prs-manual`. The shape:

1. First PR branches off `main`. Subsequent PRs branch off the current top of stack — that's what makes it a stack.
2. Submit after each phase finishes green, as a draft. Submitting per-phase is what unlocks parallel review.
3. Sync the stack at the **start** of every session, before making any commits — and again after a PR merges to `main`. A downstack merge can rebase the stack on the remote, so yesterday's local may already be stale. If you build commits on a stale base and *then* sync, the sync can favor the remote and drop your unpushed local work.
4. If you've already committed and only then notice the remote diverged: don't sync. Fetch and rebase manually — `git fetch origin <branch> && git rebase origin/<branch>` — then submit.
5. If the stack gets ~4–5 unmerged PRs deep, pause and check whether the human wants the bottom landed first.

## PR discipline

- **Always open PRs as drafts.** The human marks the PR ready for review themselves when they decide it's ready — never auto-publish a non-draft PR.
- **Create and push PRs through the stacking tool.** Going around it can set the wrong base branch and break the stack.
- **Set titles and bodies with `gh pr edit`** when the tool doesn't manage them. `--body-file` avoids heredoc escaping issues.

## Writing the PR description

Write it with the describe-work skill. The body covers this PR's own context only.

## Don't

- Don't open or push PRs the user didn't authorize. Surface "ready to submit — go?" first.
- Don't squash the stack into one PR after the fact to be tidy. If they wanted one PR they'd have said so.
