# Auto-implement plan — subagent runbook

You are spawned for **exactly one phase** of a larger plan. The orchestrator hands you the plan path, the phase number (N), and the path to your pause file at `.agents/skills/auto-implement-plan/tmp/<session-id>/phase-<N>/pause.md`.

Your job: implement the phase, commit per the phase's commit list, land it as a stacked PR on top of the previous phase's branch (or `main` for phase 1), then exit. The orchestrator handles everything else.

You **never** look at other phases of the plan. You **never** ask the human anything — if you can't decide something from the plan plus the repo, you write the pause file and exit.

## Boot

1. Read the plan file. Locate `## Phase N: <title>`. Read **only** that section.
2. Confirm `git status` is clean. If it's dirty for a reason you can't explain, pause.
3. Begin implementation.

## Implement the phase

Use the **`to-implementation` skill** as your guide for the actual work — it's the project's canonical "phase to landed code" skill. Two deviations apply here:

- **Operate fully autonomously.** Where `to-implementation` says "wait for confirmation," do not wait — proceed. The user opted into autonomous execution.
- **When `to-implementation` says "ask the human" — pause instead.** Write your pause file and exit. The orchestrator will answer and resume your session.

Commit hygiene rules (`to-implementation` already enforces these):

- Follow the phase's commit list in order. Do **not** batch. Small drifts in commit titles are fine; collapsing the count is not.
- One logical change per commit. Stage precisely; never `git add -A`.
- Short commit titles. **No `Co-Authored-By` trailer.**

## Land as a stacked PR

After the phase's commits are made and verification is green, use the **`stack-prs` skill** (which uses the **`graphite` skill**) to push this phase as a stacked PR:

- First phase branches off `main`; later phases branch off the previous phase's branch.
- Branch name: `<plan-basename>/phase-<N>-<short-slug>`.
- Submit as a draft: `gt submit --no-interactive --draft`. The human marks it ready for review.
- Set PR title and body via `gh pr edit --body-file` per the `stack-prs` conventions.

If `gt` reports an untracked-branch or stale-stack error, follow the recovery patterns in the `graphite` skill before retrying. Don't paper over with `--force`.

## Verify

Before exiting:

1. Run the project's verification command. Default for this repo: `pnpm test && pnpm lint && pnpm typecheck`. The plan or repo `AGENTS.md` may override.
2. If red, fix and recommit. Don't pause for routine fixes — fixing your own test failures is part of the job.
3. If a fix requires a load-bearing decision the plan doesn't cover, **then** pause.

## When to pause (precisely)

Pause only when **all three** are true:

- The plan section for phase N doesn't tell you what to do.
- The repo state (existing code, tests, types) doesn't disambiguate either.
- The decision is load-bearing — guessing wrong would break this phase or downstream phases.

Do **not** pause for: variable names, picking between two equivalent approaches the plan didn't constrain, test-layout decisions when the project already has a clear convention (see `AGENTS.md`), or anything you can resolve by reading one more file.

### How to pause

Write the pause file the orchestrator told you about:

```markdown
## Question
<Specific, decidable question. Not "what should I do?" — "should I X or Y, given Z?">

## Where I am
- Phase N, partway through commit M ("<commit title from plan>").
- Commits made so far: <hash> ("<title>"), <hash> ("<title>").
- Next planned commit: "<title>".
- Branch: <branch name>.
- What I tried / why I'm stuck: <one or two sentences>.
```

Then exit cleanly. Do **not** make a partial commit just to checkpoint — leave any uncommitted work in the working tree.

### How resume works

You will **not** be re-spawned from scratch. The orchestrator resumes your **same** CLI session with a new message pointing you at the answered pause file. Your prior context — what you read, what you tried, where you were — is intact.

When you receive the resume message:

1. Re-read the pause file. The orchestrator has appended `## Answer`.
2. Apply the answer and continue from exactly where you paused.
3. When the phase is fully done (commits + green + PR), exit cleanly.

## Done

When the phase is committed, green, and PR'd:

1. Delete the pause file if it exists.
2. Print a one-line summary to stdout (e.g., `Phase N complete: <branch> @ <PR url>`).
3. Exit cleanly with status 0.

If you hit a hard stop you cannot resolve (e.g., `gt submit` fails for an unrecoverable reason and you've exhausted the documented recovery in the `graphite` skill), exit with non-zero status. The orchestrator treats the attempt as failed.

You do **not** write `state.json`. The orchestrator owns it.

## What you never do

- Read other phases' sections of the plan.
- Commit to `main` directly. Stacked PRs handle branching; you should always be on a feature branch.
- Squash, force-push without explicit recovery instructions, or land PRs (mark ready / merge). Drafts only.
- Ask the human anything via stdout, chat, or PR comments. Use the pause file or nothing.
- Add a `Co-Authored-By` trailer to commits.
- Edit files outside the scope of phase N.
- Write to the orchestrator's `state.json`.
