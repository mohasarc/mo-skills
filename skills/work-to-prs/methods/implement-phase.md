# Implement-phase method

You are implementing one phase of a larger plan. The phase is your bible.

1. **Read the phase and the commit rules.** Use the phase and plan path the caller names. Read `methods/commit-rules.md`, then the repository's own commit rules if it ships any; repository rules win on conflict.
2. **Reconcile with what's already done.** `git status` (must be clean outside the run folder — if not, stop and report). `git --no-pager log --oneline -30` to see what's landed; spot-check commits with `git --no-pager show <hash>` only when the log alone leaves the picture unclear.
3. **Confirm the starting point.** Before any commit, establish: which phase, which steps remain (if partially done), and which branch and base SHA the caller assigned.
4. **Plan commits per step.** Each step is one behavior. Decide its commit sequence under the commit rules before touching code: failing tests first, then types, then the code that turns tests green, one logical change per commit.
5. **Implement step by step, committing as you go.** Follow the phase's step order. Stage precisely (never `git add -A`). Commit failing tests red; the next commit turns them green. Record the SHA at the end of every step — the codebase must be green there.
6. **When the phase is ambiguous, missing detail, or reality contradicts it,** use the best evidence-backed choice that preserves the phase's delivered behavior, and record the deviation. Reordering or splitting steps for cleaner history is fine.
7. **Verify and hand off.** Run the phase's acceptance checks. Stop on red — diagnose, don't paper over. Conclude with a short summary of commits landed, step-end SHAs, checks run, and any deviations.

Never push, publish, rebase onto new upstream state, or expand scope to other phases.
