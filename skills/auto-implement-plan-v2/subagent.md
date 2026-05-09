# Auto-implement plan — subagent runbook

You are spawned for **exactly one phase** of a larger plan. The orchestrator will tell you which plan and which phase. The mechanics of how you talk to the orchestrator are the host tool's responsibility — focus on **what** you do.

## Your responsibilities

- **Read only your phase.** Locate `## Phase N: <title>` in the plan and read that section. Do not skim other phases — they're not your concern.
- **Implement the phase via the `to-implementation` skill** — it's the project's canonical "phase to landed code" skill. Two deviations apply here:
  - You operate fully autonomously. Where `to-implementation` says "wait for confirmation," do not wait — proceed.
  - Where `to-implementation` says "ask the human," **ask the orchestrator instead** (see *When to pause*). Never message the human.
- **Land the phase as a stacked draft PR** via the `stack-prs` skill (which uses the `graphite` skill). The first phase branches off `main`; later phases branch off the previous phase's branch. Always submit as a draft — the human decides when something is ready for review.
- **Verify before declaring done.** Run the project's verification command (default for this repo: `pnpm test && pnpm lint && pnpm typecheck`; the plan or `AGENTS.md` may override). Make it green before exiting. Routine fixes don't justify pausing — fixing your own failures is part of the job.
- **Report back.** When the phase is committed, green, and PR'd, give the orchestrator a short summary: branch name, commit titles, PR URL. That's all it should need.

## Commit hygiene

- Follow the phase's commit list in order. Do **not** batch. Small drifts in commit titles are fine; collapsing the count is not.
- One logical change per commit. Stage precisely; never `git add -A`.
- Short commit titles. **No `Co-Authored-By` trailer.**

## When to pause

Pause only when **all three** are true:

- The plan section for this phase doesn't tell you what to do.
- The repo state (existing code, tests, types, conventions in `AGENTS.md`) doesn't disambiguate either.
- The decision is load-bearing — guessing wrong would break this phase or downstream phases.

Do **not** pause for: variable names, picking between two equivalent approaches the plan didn't constrain, test-layout decisions when the project already has a clear convention, or anything you can resolve by reading one more file.

When you pause, surface a **specific, decidable question** to the orchestrator (not "what should I do?" — "should I X or Y, given Z?") along with where you are: which commit you're on, what's already committed, what's next, and what you tried. The host tool will deliver this and let you continue once the orchestrator answers — your context is preserved across the pause.

## What you never do

- Read other phases of the plan.
- Commit to `main`. Stacked PRs handle branching; you should always be on a feature branch.
- Squash, force-push without explicit recovery instructions, or mark a PR ready / merge it. Drafts only.
- Ask the human anything. Direct all questions to the orchestrator.
- Add a `Co-Authored-By` trailer to commits.
- Edit files outside the scope of phase N.
