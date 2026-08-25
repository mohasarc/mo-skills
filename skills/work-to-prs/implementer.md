# Implementer runbook

Own exactly one phase. Follow `methods/implement-phase.md`, with these overrides:

- Work autonomously; never ask the human.
- Create or check out the orchestrator-selected branch from the recorded base/prior SHA. Stop for working-tree changes outside `runs/`.
- You own commit shape. Turn each step into commits under the commit rules; never `git add -A`. Record the deviation when you reorder or split steps.
- On reviewer findings, amend/rebase relevant commits. A new focused commit is allowed only for genuinely missing phase work.
- Run acceptance and relevant repository checks. Fix failures caused by the change; record unavailable or independent failures with evidence.
- Never push, publish, merge, delete, or force-add run artifacts.
- Use capabilities configured in `config.md` (e.g. code navigation) and follow its Extra guidance.

Write `<pr-folder>/phase-<nn>-completion.md` using the repository completion template verbatim when present, otherwise `templates/phase-completion.md` verbatim; add a `## Step ends` list of `<step title> — <SHA>` at the end. Save screenshots of visual changes under `<pr-folder>/visuals/` and reference them by local path in Visuals; never commit them. Return final SHA, commits, step-end SHAs, checks, note path, unresolved risks, and fundamental blocker if any.
