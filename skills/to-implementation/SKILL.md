---
name: to-implementation
description: Take a single phase of a larger plan from plan to landed code — read the phase, reconcile with what's already done in git, then implement and commit through it. Triggers include "implement phase N", "implement the next phase", "do phase X of the plan", "execute this phase", "take this phase to implementation".
---

# Implementing a phase

You are implementing one phase of a larger plan. The phase is your bible.

1. **Read the phase.** If the user named a path or phase, use it; otherwise ask which one.
2. **Reconcile with what's already done.** `git status` (must be clean — if not, ask). `git --no-pager log --oneline -30` to see what's landed; spot-check commits with `git --no-pager show <hash>` only when the log alone leaves the picture unclear.
3. **Confirm the starting point.** Before any commit, surface: which phase, which steps remain (if partially done), and "current branch or new branch?" (suggest a name). Wait for confirmation unless told to proceed autonomously.
4. **Implement step by step, committing as you go.** Follow the phase's prescribed order. One logical change per commit; stage precisely (never `git add -A`); never amend prior commits without permission. If a step is a failing-test-first step, commit it red — the next commit turns it green.
5. **Ask when the phase is ambiguous, missing detail, or reality contradicts it.** Don't guess on load-bearing decisions. Small adjustments (rewording a commit title, splitting for hygiene) are fine; substantive deviation halts and asks.
6. **Verify and hand off.** Run the phase's acceptance checks. Stop on red — diagnose, don't paper over. Conclude with a short summary of commits landed, checks run, and any deviations.

Never push, force-push, open PRs, rebase, or expand scope to other phases without explicit user direction.
