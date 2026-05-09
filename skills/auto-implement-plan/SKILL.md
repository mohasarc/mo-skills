---
name: auto-implement-plan
description: Drive a multi-phase plan to completion autonomously by spawning fresh-context subagents — one per phase — that land each phase as a stacked PR. Use when the user wants a phased plan executed end-to-end without supervising commit-by-commit. Triggers include "auto-implement this plan", "run this plan unattended", "drive plans/X/plan.md to completion", "execute the whole plan", "hand this plan off and run it".
---

# Auto-implement plan (orchestrator)

You drive a phased plan to completion by spawning a fresh-context subagent for each phase. **You never write code or make commits yourself.** Your jobs are: spawn subagents, answer their pause questions (resuming the same session), run verification, decide retry / advance / abort.

Why this works: each subagent runs in a separate process with fresh context, so the original failure mode (context dilution late in long autonomous runs) doesn't apply at the phase level. You keep your own context small by tracking phases through one durable file — never reading subagent transcripts.

## Inputs

The user invokes you with a path to a phased plan: a single Markdown file with `## Phase N: Title` h2 sections.

You also need a CLI command pair for spawning and resuming subagents — different agent CLIs use different flags:

- **NEW-session command**: invoke a fresh subagent with a stored session ID. Example shapes: `claude -p --session-id <id> "<prompt>"`, `codex exec --session <id> "<prompt>"`.
- **RESUME-session command**: append a message to an existing session. Example: `claude -p --resume <id> "<message>"`, `codex exec --resume <id> "<message>"`.

If the user didn't specify, default to the same CLI you're running in. Confirm exact flags via `<cli> --help` once at startup; cache them.

## State — one file

Per session, only one durable file:

```
.agents/skills/auto-implement-plan/tmp/<session-id>/state.json
```

Shape:

```json
{
  "plan_path": "plans/feature-x/plan.md",
  "plan_basename": "feature-x",
  "started_at": "2026-05-08T10:23:45Z",
  "status": "running",
  "phases": [
    {
      "n": 1,
      "title": "...",
      "status": "complete",
      "subagent_session_id": "ss-abc123",
      "branch": "feature-x/phase-1-...",
      "pr_url": "https://...",
      "attempts": 1,
      "pauses": 0
    },
    { "n": 2, "title": "...", "status": "running" },
    { "n": 3, "title": "...", "status": "pending" }
  ]
}
```

You own this file. Subagents do not write to it. Update it as phases progress.

## Session bootstrap

1. Compute candidate session ID: `<plan-basename>-<ISO-timestamp>`.
2. Check `.agents/skills/auto-implement-plan/tmp/` for an existing `<plan-basename>-*` session whose `state.json` has status `running`. If found, resume it (use its session ID).
3. If new session: parse the plan, list every `## Phase N` heading, write `state.json` with all phases as `pending`.
4. Determine the next phase: the lowest-N phase whose status isn't `complete`.

## Per-phase loop

For each non-`complete` phase N:

1. **Generate a subagent session ID** (e.g., `<session-id>-p<N>-a<attempt>`). Record in `state.json`.
2. **Spawn the subagent** via Bash using the NEW-session command. Prompt body:
   - Plan path and phase number N.
   - Path to `.agents/skills/auto-implement-plan/subagent.md` (the runbook to follow).
   - Path to its phase pause file: `.agents/skills/auto-implement-plan/tmp/<session-id>/phase-<N>/pause.md`.
3. **Wait for it to exit.** Do not read its stdout into your context.
4. **Inspect outcome — in this order:**
   - **Pause:** if `phase-<N>/pause.md` exists with a `## Question` and **no** `## Answer` → see *Pause handling*. Don't run verification.
   - **Verification:** run the project's verification command. Default for this repo: `pnpm test && pnpm lint && pnpm typecheck`. The plan or repo `AGENTS.md` may override. If red → failed attempt.
   - **Commits made:** confirm at least one new commit on the phase's branch since spawn. If zero → failed attempt.
   - **PR submitted:** confirm a draft PR exists for the phase's branch (e.g., `gh pr list --head <branch>`). If missing → failed attempt.
   - **Success:** all checks pass → mark phase `complete` in `state.json`, advance to N+1.
5. **Retry policy.** Up to **3 attempts per phase**. Each retry uses a NEW subagent session ID (fresh context), with a `## Failure summary` (1–2 sentences per prior attempt) appended to the prompt. After 3 failed attempts, abort.

## Pause handling

When phase N's `pause.md` shows up with an unanswered Question:

1. Read `## Question` and `## Where I am`.
2. Answer using **only**: the plan file (re-read fresh), repo state (`git status`, `git log`, file contents on disk), prior phases' summaries from `state.json`, and your own reasoning. Do not read the subagent's transcript.
3. Append `## Answer` to `pause.md` with a clear, decisive answer.
4. **Resume the subagent's existing session** via the RESUME-session command. The message you send is something like: *"Your pause file has been answered. Read `<pause-path>` and continue from where you stopped."* The subagent's prior context is preserved by the CLI; it sees the answer and continues from exactly where it paused — no fresh-spawn rebuild.
5. Increment `pauses` for this phase in `state.json`.

**If you cannot answer**: abort. There is no human to escalate to.

**Cap pauses per phase at 3.** A 4th pause means the plan is too underspecified — abort.

## Context discipline

The single most important rule for surviving long runs:

- After each phase, the only thing you ingest into your own context is what you yourself write to `state.json` (statuses, commit hashes, PR URLs, brief pause Q&As).
- **Never** read the subagent's stdout/stderr or its CLI transcript file.
- Re-read the plan section for phase N+1 fresh from disk before spawning the next subagent. Don't rely on memory.

## Termination

### Complete

When the last phase passes verification:

1. Set `state.json` `status: "complete"`.
2. Exit cleanly. Do not push, force-push, merge, or land any PR — the human takes over.

### Abort

When you can't make progress (3 failed attempts on a phase, an unanswerable pause, or a 4th pause on the same phase):

1. Set `state.json` `status: "aborted"` and add a top-level `abort_reason` field.
2. Exit cleanly. The human inspects `state.json` and decides what to do.

## What you never do

- Edit code or make commits. Subagents do that.
- Read another subagent's transcript or stdout.
- Squash, rebase, force-push, or land PRs. The human decides what merges.
- Ask the human anything mid-run. Either answer the pause yourself, or abort.
- Operate on `main`. Phases land via stacked PRs on feature branches.
