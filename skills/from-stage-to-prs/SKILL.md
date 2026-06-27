---
name: from-stage-to-prs
description: Drive a single stage from a stages document all the way to a stack of reviewed PRs, autonomously. Loads one stage, runs a two-agent design dialogue to narrow it down, turns the agreed design into a committed phased plan, then implements each phase as a stacked draft PR gated by a strict per-phase review. Use when you want to hand off a whole stage and walk away. Triggers include "take stage N to PRs", "from stage to prs", "implement stage N end to end", "drive this stage to a stack".
---

# From stage to PRs (orchestrator)

You drive **one stage** from a stages document to a stack of reviewed draft PRs, autonomously. You delegate every unit of real work to a fresh-context subagent and only ever ingest compact reports back. The mechanics of spawning, resuming, and messaging subagents are the host tool's responsibility — focus on **what** you do.

## Invocation

`/from-stage-to-prs <stages-file> <stage-id> [--checkpoint]`

- `<stages-file>` — path to the stages document (`## Stage N — <name>` sections).
- `<stage-id>` — the stage number to implement. One stage per run.
- `--checkpoint` — off by default. When set, you stop once after the plan PR is open and wait for the human's okay before phase 1.

## Why this exists

Two failure modes are being avoided at once.

1. **Shallow design.** A single agent that both designs and builds rushes the design — it implements its first instinct. A stage is too coarse to implement directly; it needs to be narrowed into a concrete phased plan first.
2. **Context dilution over long runs.** After hours of work, one agent loses fidelity to the plan and collapses structure (bundling commits, skipping review). The remedy is fresh context per unit of work, and an orchestrator that stays lean by ingesting only compact summaries — never transcripts, never dialogue.

The orchestrator's leanness is load-bearing. **You must never read a design dialogue or a review back-and-forth.** Reading them defeats the whole point.

## The run, end to end

1. **Load the stage.** Read `<stages-file>` and locate `## Stage <stage-id>`. Confirm it exists. You do not need its body in your own context beyond a one-line identity — the planning agent reads it fresh.
2. **Spawn the planning agent (A).** Hand it `planning-driver.md` as its runbook, plus the stages-file path and stage-id. A runs the design dialogue with B itself, reaches agreement, writes the phased plan, commits it, and opens it as the bottom draft PR of the stack. **You stay out of the dialogue entirely.** A returns one compact report: plan file path, branch, plan PR URL, and any open questions it recorded.
3. **Checkpoint (only if `--checkpoint`).** Surface the plan PR URL and any open questions to the human and stop. Resume into step 4 when they okay it. Without `--checkpoint`, go straight to step 4.
4. **Enumerate phases.** Read the committed plan file from disk to list its phases (`## Phase N — <title>`). Re-read each phase's section fresh from disk immediately before delegating it — never paraphrase from memory.
5. **Implement each phase, in order.** Delegate phase N to a fresh implementer with `implementer.md` as its runbook. The implementer implements, self-reviews via a reviewer subagent it hosts, and opens the stacked draft PR only after the review passes. It returns a compact report: branch, commit titles, phase PR URL.
6. **Verify each phase before advancing.** Re-run the verification command (see below) and confirm the stacked draft PR exists. If either is wrong, the phase failed regardless of what the implementer claimed.
7. **Stop cleanly.** When the last phase verifies, exit with the stack summary. On abort, surface why.

## Verification command

Default: `pnpm test && pnpm lint && pnpm typecheck`. If those fail or don't apply to this project, find the real commands for tests / lint / typecheck in `package.json` scripts, `AGENTS.md`, or other project config, and use those. Use the same command everywhere in the run.

## Bounded retry

Up to three attempts per phase, each a fresh-context implementer handed a brief summary of the prior failure. A phase fails if the implementer reports `phase-failed` (its review loop didn't converge) or your verification doesn't pass. After three attempts, abort and surface where.

## Context discipline

- The only things you ingest are compact reports: from A (plan path, branch, PR URL, open questions) and from each implementer (branch, commit titles, PR URL, or `phase-failed`).
- **Never** read a subagent's transcript, the A↔B design dialogue, or the implementer↔reviewer review exchange.
- Re-read the plan section for the next phase from disk before delegating; don't rely on memory.

## What you never do

- Edit code, run tests outside the verification command, or make commits. Subagents do that.
- Read any dialogue or review exchange.
- Answer design questions yourself — that's B's job, inside A.
- Squash, rebase, force-push, or mark PRs ready / merge them. The human decides what merges.
- Ask the human anything mid-run, except the single optional `--checkpoint` pause. Otherwise answer from the plan and repo state, or abort.
- Operate on `main`. The plan and every phase land via stacked draft PRs on feature branches.

## Fallback: no nested spawning

The design above assumes a subagent can spawn and hold a multi-turn conversation with another subagent (A hosts B; implementer hosts reviewer) without you in the loop. If the host does not allow a subagent to spawn its own children, fall back to **blind shuttling**: the two agents exchange through a scratch message-log file, and you pass turn control between them — "your turn, read the log, append your reply" — **without ever reading the log's contents**. The context-discipline guarantee is unchanged; only the plumbing differs.
