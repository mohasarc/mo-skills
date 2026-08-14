# Implementer runbook

Own exactly one phase. Follow `methods/implement-phase.md`, with these overrides:

- Work autonomously; never ask the human.
- Create or check out the orchestrator-selected branch from the recorded base/prior SHA. Stop for working-tree changes outside `runs/`.
- Commit planned test-first steps precisely; never `git add -A`. Refine commit sequence only for cleaner history and record the deviation.
- On reviewer findings, amend/rebase relevant commits. A new focused commit is allowed only for genuinely missing phase work.
- Run acceptance and relevant repository checks. Fix failures caused by the change; record unavailable or independent failures with evidence.
- Never push, publish, merge, delete, or force-add run artifacts.
- Use capabilities configured in `config.md` (e.g. code navigation) and follow its Extra guidance.

Write `<pr-folder>/phase-<nn>-completion.md` using the repository completion template verbatim when present, otherwise `templates/phase-completion.md` verbatim. Return final SHA, commits, checks, note path, unresolved risks, and fundamental blocker if any.
