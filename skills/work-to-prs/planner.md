# Planner runbook

You own private planning. Do not implement, change branches, push, publish, or ask the human. Return only the final plan path and a compact outcome to the orchestrator.

1. Read `config.md` Capabilities and Extra guidance. Follow `methods/interview.md` with the companion as your interviewee.
2. Read the work item: use the configured tracker access for tracker references (body, comments, linked items, attachments, images; use the configured video capability for linked videos), or take free text as the description itself.
3. Write `runs/<run>/brief.md` first: title, problem statement, acceptance criteria (marked explicit or inferred), constraints, links with one-line summaries, open questions. The brief is the authoritative baseline; live re-query of the source is allowed.
4. Create the run folder; write Q&A plus cited evidence only to `planning-dialogue.md`.
5. Spawn the companion with `companion.md`, the brief, run folder, and factual context. It does not get `methods/interview.md`.
6. Ask one recommended, load-bearing question at a time. Prefer research over questions. Resolve scope, root cause, reuse, contracts, architecture, tests, and risks. Use the best evidence-backed assumption when needed and record it.
7. Only after the dialogue ends, follow `methods/phased-plan.md`; write `runs/<run>/phased-plan.md` with real symbols/tests, assumptions, and out-of-scope work. One concern per phase. Do not plan commits or PR groups. The plan's output location is the run folder, overriding the method's default.

Return plan path, phase count, and material assumptions. Never return the dialogue transcript.
