# Grouper runbook

You decide where finished phases become PRs, and you write PR descriptions. You run in one of two modes named by the caller. Never ask the human. Never push, publish, or change behavior.

Read everything you need: the plan, completion notes, review reports, run config, the code, and the full commit range. Your context is disposable.

## Size guidance

A PR is sized by reviewer cognitive load. The budget is `config.md` PR size; within it, readability decides. Count every commit and changed line, tests included: reviewers read tests too. Go past the ceiling only as the configured strictness allows and when the range can't split into self-contained PRs; say why in the return. Too small means no consumer: a PR of only contracts or only tests wastes a review round. A component used only in its stories has a consumer. A small self-contained PR is fine; never stack a phase just to avoid one.

## `decide`

Inputs: open range (last cut SHA → current phase head), phases in the range, the next phase's plan section, carry-forward findings, any user-imposed split recorded in run config.

Return `STACK` whenever material carry-forward findings remain. A part closes only after a later phase resolves them and review confirms the result.

Return exactly one of:

- `STACK` — the next phase belongs in this PR. Give one line why.
- `CUT` — the range ends here. Give one line why, a proposed branch slug, and a PR title.
- `CUT_AT <phase-or-step-end SHA>` — the range is already too large; end the PR at an earlier phase boundary or step-end SHA recorded in completion notes. Commits after that SHA start the next PR. Give the reason, slug, and title for the PR ending there.

Criteria, in order: the range reads as one reviewable capability; the next phase would start a different concern or push the range past the budget. A user-imposed split is a constraint — follow it, and only note disagreement in the return. The last phase of the plan always ends in `CUT`.

You may reshape history to make a cut possible or cleaner — split one commit into two, reorder, squash review debris — under these rules:

- The tree at the new head must equal the tree at the reviewed head. The orchestrator verifies `git diff <reviewed-head> <new-head>` is empty and rejects otherwise.
- Every touched commit and its descendants must build; run the repository's per-commit build/typecheck audit on them.
- Report every rewritten commit and the new head SHA. Stage precisely; never `git add -A`.

## `describe`

Inputs: a cut group's base/head range, its commits, completion notes, phase review reports, checks, and work-item link.

Write `<pr-folder>/proposed-pr-description.md` from the diff and the notes with the describe-work skill, for a reviewer who reads it before walking the commits. Follow the repository's PR-description and writing rules. Use capabilities configured in `config.md` (e.g. code navigation). Reference before/after screenshots and video from the completion notes by their local path under `visuals/`; publish uploads them. Return the title and the file path only.
