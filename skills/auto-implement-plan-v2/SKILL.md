---
name: auto-implement-plan-v2
description: Drive a multi-phase plan to completion autonomously by delegating each phase to a fresh-context subagent that lands the work as a stacked PR. Use when the user wants a phased plan executed end-to-end without supervising commit-by-commit. Triggers include "auto-implement this plan", "run this plan unattended", "drive plans/X/plan.md to completion", "execute the whole plan", "hand this plan off and run it".
---

# Auto-implement plan (orchestrator)

You drive a phased plan to completion by delegating each phase to a fresh-context subagent. The mechanics of spawning, resuming, and communicating with subagents are the host tool's responsibility — focus on **what** you do, not **how**.

## Why this exists

The failure mode being avoided is **context dilution over long autonomous runs**: after a few hours, the agent that's been doing all the work loses fidelity to the original plan and starts collapsing structure (e.g., bundling planned commits into one). The remedy is to give every phase a subagent with fresh context, and to keep your own context small by only ever ingesting compact summaries from each subagent — never their transcripts.

## Your responsibilities

- **Read the plan once** to enumerate its phases (`## Phase N: Title` h2 sections), then re-read each phase's section *fresh from disk* immediately before delegating it. Don't rely on memory of the plan as the run grows.
- **Delegate each phase, in order, to a fresh subagent.** The subagent's job is described in `subagent.md` (next to this file); hand that to it as its runbook.
- **Track which phases are complete.** Use whatever the host tool provides for durable state. The status of a phase is a function of what the subagent reports plus your own verification — not a guess.
- **Verify each phase before advancing.** Re-run the project's verification command (default for this repo: `pnpm test && pnpm lint && pnpm typecheck`; the plan or `AGENTS.md` may override). Confirm a stacked draft PR was opened for the phase. If either is wrong, the phase failed regardless of what the subagent claimed.
- **Answer pause questions yourself.** When a subagent reports it's stuck, answer using the plan, repo state, your prior phase summaries, and your own reasoning. There is no human to escalate to. If you genuinely cannot answer, abort.
- **Retry on failure, bounded.** Up to three attempts per phase, each with a fresh-context subagent and a brief failure summary. After three, abort.
- **Stop cleanly.** When the last phase verifies, exit. When you abort, surface why. The human never decides mid-run; they only see the final outcome.

## Context discipline

This is the rule that keeps long runs faithful:

- The only thing you ingest from a subagent is its short report on the phase: status, commit titles, PR URL, and any pause Q&A. Nothing more.
- **Never** read a subagent's transcript or full output stream.
- Re-read the plan section for the next phase from disk before delegating; don't paraphrase it from memory.

## What you never do

- Edit code, run tests outside the verification command, or make commits. Subagents do that.
- Read another subagent's transcript.
- Squash, rebase, force-push, or land PRs. The human decides what merges.
- Ask the human anything mid-run. Either answer the pause yourself, or abort.
- Operate on `main`. Phases land via stacked PRs on feature branches.
