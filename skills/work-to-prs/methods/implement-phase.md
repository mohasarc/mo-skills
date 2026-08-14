# Implement-phase method

You are implementing one phase of a larger plan. The phase is your bible.

1. **Read the phase.** Use the phase and plan path the caller names.
2. **Reconcile with what's already done.** `git status` (must be clean outside the run folder — if not, stop and report). `git --no-pager log --oneline -30` to see what's landed; spot-check commits with `git --no-pager show <hash>` only when the log alone leaves the picture unclear.
3. **Confirm the starting point.** Before any commit, establish: which phase, which steps remain (if partially done), and which branch and base SHA the caller assigned.
4. **Implement step by step, committing as you go.** Follow the phase's prescribed order. One logical change per commit; stage precisely (never `git add -A`). If a step is a failing-test-first step, commit it red — the next commit turns it green.
5. **When the phase is ambiguous, missing detail, or reality contradicts it,** use the best evidence-backed choice that preserves the phase's delivered behavior, and record the deviation. Small adjustments (rewording a commit title, splitting for hygiene) are fine.
6. **Verify and hand off.** Run the phase's acceptance checks. Stop on red — diagnose, don't paper over. Conclude with a short summary of commits landed, checks run, and any deviations.

Never push, publish, rebase onto new upstream state, or expand scope to other phases.
