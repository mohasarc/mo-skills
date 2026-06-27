# Planning driver (agent A) — runbook

You turn **one stage** into a committed phased plan, then open it as the bottom PR of a stack. You do this by drilling into the stage and resolving every design decision with a second agent (B) you host yourself. The orchestrator that spawned you stays out of this entirely — it sees only your final report.

The orchestrator gives you: the stages-file path, the stage-id, and the verification command.

## What you read

- The target stage in full (`## Stage <stage-id>` in the stages file).
- The stages doc's **Beyond Scope** and sequencing summary, for boundary awareness only.
- Do not read other stages' bodies. They are not your unit of work.

## The design dialogue

1. **Load `/drill-down`.** Drill into the target stage: scope, site of change, collaborators, new shapes, behavior and contracts, testing, constraints, risks. One question at a time, each with a concrete recommended answer — same as drill-down normally works.
2. **B is your counterpart, not the human.** Spawn B once and keep it alive for the whole dialogue. Hand it `answerer.md`, the stages-file path, and the stage-id. Every question you'd put to a human, you put to B instead. Explore the codebase yourself first — never ask B something the code already answers.
3. **Walk the dependency tree.** Earlier answers narrow later questions. Stop inventing questions once no load-bearing unknown remains.

## Reaching agreement

The dialogue ends only on a two-sided, deterministic handshake keyed to a decision summary — not on you running out of questions.

1. When you believe the design is concrete enough to build, emit a **consolidated decisions list**: every resolved point, terse, one line each. Follow it with a sentinel line on its own: `READY-FOR-PLAN`.
2. B replies with either the exact token `AGREED`, or a list of specific objections / still-open points.
3. Only the exact `AGREED` lets you proceed. Anything else re-opens the loop — address the points and re-summarize.
4. **Soft cap ~40 exchanges.** If you hit it without `AGREED`, do not hang and do not abort: finalize with the decisions you have, record everything still unresolved as explicit open questions, and proceed to the plan.

## Writing and landing the plan

1. **Load `/to-phased-plan`.** Produce the phased plan from the agreed decisions in your context. Record any open questions in the plan where the relevant phase would resolve them.
2. **Branch and commit.** `gt sync` first. Branch off `main`. Commit the plan file as `docs: add phased plan for stage <stage-id>`. Never commit to `main`. No `Co-Authored-By` trailer; short title.
3. **Open the bottom PR.** Submit as a draft via the `stack-prs` skill (`gt submit --no-interactive --draft`). This is the root of the stack; phases will stack on top. Write the PR description per the repo's `PULL_REQUEST_TEMPLATE.md`.

## Report back

Return one compact report to the orchestrator: plan file path, branch name, plan PR URL, and any open questions you recorded. Nothing else — not the dialogue, not B's answers.

## What you never do

- Surface the dialogue to the orchestrator or the human.
- Commit to `main`, mark the PR ready, or merge it. Drafts only.
- Ask the human anything — B is your only counterpart, and B never escalates to a human either.
- Add a `Co-Authored-By` trailer.
