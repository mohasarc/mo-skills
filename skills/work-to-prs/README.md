# work-to-prs

Hand the agent a work item, get back reviewed, ready-to-publish PRs. The pipeline: a planner and a private companion agent research the codebase and interview each other until the design is settled, the work is broken into TDD phases with strict commit hygiene, each phase is implemented by a fresh agent and gated by a fresh strict reviewer, and everything lands as local branches plus markdown artifacts. Nothing is pushed or published until you explicitly say so.

## Install

```sh
npx skills install mohasarc/mo-skills --skill work-to-prs
```

## Quick start

```text
work-to-prs fix the double-submit bug on the checkout form
work-to-prs PROJ-123
work-to-prs https://github.com/you/repo/issues/42
```

Output lands in `runs/<run>/` inside the skill folder (git-ignored): brief, phased plan, planning dialogue, per-phase completion notes, review reports, and a proposed PR description per branch. The handoff report ends with the exact publish command.

```text
work-to-prs resume <run-folder>    # continue an interrupted run
work-to-prs publish <run-folder>   # push and open PRs per your config
```

## Configure

Edit `config.md` beside `SKILL.md`. It ships with working defaults; every line is a plain-sentence rule the agents follow. The sections:

- Reading work items — how input becomes a brief. Default: plain text is the work description. Point it at your tracker, e.g. "Use the linear-read skill for Linear IDs and URLs. Tracker is read-only."
- Models — model per agent role, e.g. "Planner: opus". Unset roles use the harness default.
- Publication — what `publish` does (draft PRs / ready PRs / push only) and when (all at once on command / per group as each passes review).
- Runs — where run output lives and whether to keep it. Default: keep everything.
- Conventions — integration branch, branch naming, verification commands. Left on "discover", the agent reads your repo docs and asks before recording what it found.
- Capabilities — optional tools agents may use, all off by default.
- Extra guidance — freeform project rules passed verbatim to every agent. Rules here override the workflow's defaults, so this is also where you relax core behavior (e.g. drop TDD) if you must.

## Suggested third-party tools

None required. If installed and named in config, agents use them:

- [linear-read](https://github.com/mohasarc/mo-skills) — Linear issue access, for the Reading work items section.
- [symnav](https://github.com/mohasarc/symnav) — TypeScript symbol navigation, for the Code navigation capability.
- [loom-watch](https://github.com/mohasarc/mo-skills) — Loom transcripts and frames, for the Video links capability.
- [change-tree-svg](https://github.com/mohasarc/change-tree-svg) — rendered file-tree embeds in PR descriptions, for the PR tree embeds capability.

Any equivalent tool works; the config sentence just has to name it.

## Requirements

Works on any agent harness that can load markdown skills. Harnesses that can spawn subagents get the full design: isolated planner/companion dialogue and fresh implementer/reviewer contexts per phase. Harnesses without subagents degrade to playing the roles sequentially in one context; the run still completes and the handoff report discloses the lost isolation.

Note: reinstalling or updating the skill can overwrite your edited `config.md`. Diff and carry your rules over after an update.
