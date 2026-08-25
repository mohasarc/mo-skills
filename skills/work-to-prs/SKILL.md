---
name: work-to-prs
description: Take any work item — tracker issue, URL, or plain text — through private two-agent planning, phased TDD implementation, strict per-phase review, diff-driven PR grouping, local PR artifacts, and explicit configurable publication. Use when the user wants a work item implemented end to end, wants PR proposals prepared, or asks to resume or publish from this workflow.
metadata:
  version: "2.0.0"
---

# Work to PRs

Implement any work item end to end. Complexity is not a gate. Nothing is published without the explicit `publish` command.

This workflow owns its implementation and review rules. Its methods are bundled under `methods/`; do not use or read outside implementation-orchestration or review skills for its rules.

## Modes

| Invocation | Behavior |
| --- | --- |
| `work-to-prs <tracker ref, URL, or free text>` | Research, plan, implement, review, group, and create local artifacts. Never push or publish. |
| `work-to-prs resume <run-folder>` | Validate durable state and continue incomplete work. |
| `work-to-prs publish <run-folder>` | Execute the publication behavior set in `config.md`. |

Never infer `publish` from an implementation request. Before doing anything, `publish` prints one line stating exactly what it is about to do (e.g. "opening 2 draft PRs targeting development").

## Config

`config.md` beside this file is the project rules file. Read it at preflight. Its Extra guidance rules pass verbatim to every agent. For unset Conventions values, discover from repository docs; after a successful run, offer to record discovered values into `config.md` and write only after the user agrees.

## Capabilities

Input access and optional tooling come from the project, not this skill. Use what `config.md` names: tracker access (project skill, MCP, or CLI), code navigation, video links, PR tree embeds, PR image upload. If input references a tracker and no access method is configured or discoverable, stop with a clear report. Treat the tracker as read-only unless config says otherwise.

## Agents

Spawn subagents natively through the harness, passing the role's runbook file and the model hint from config's Models section. Unset hints mean harness default; an unavailable hint falls back to default and is noted in the handoff. If the harness cannot spawn subagents, play the roles sequentially in one context and disclose the lost context isolation in the handoff.

Roles: planner (+ companion), implementer, reviewer, grouper. Each spawn is fresh; only the implementer is resumed, and only for review fixes within its phase.

## Boundaries

- Run phases, reviews, and grouping decisions sequentially.
- Never push, create PRs, merge, delete, stash, or discard work in implementation mode.
- Stop if user-owned working-tree changes exist. `runs/` is git-ignored; never force-add it.
- Preserve branches and artifacts after all outcomes.
- Orchestrator reads only the brief, phased plan, run config, git status, completion notes, review verdicts, and grouper returns. Never read planning dialogue, subagent transcripts, implementation code, or PR descriptions. Anything that needs the diff goes to a subagent.

## Workflow

### Preflight and planning

1. Read `config.md`. Classify input: configured tracker reference, or free text used as the work description. Read repository instructions for unset conventions: integration branch, branch convention, PR templates, verification commands. Use the documented integration branch or `development`, then `main`.
2. Confirm working tree has no user-owned changes. Update base only as repository rules allow and record base SHA. Do not update it mid-run.
3. Spawn planner with `planner.md`; planner alone spawns companion with `companion.md`. Orchestrator never receives their messages.
4. Planner writes `runs/<run>/brief.md`, `phased-plan.md`, and `planning-dialogue.md`. It returns only plan path, phase count, and material assumptions.
5. Create `run-config.md` from `templates/run-config.md`, recording the work reference, base SHA, branch convention, commands, and any user-imposed PR split.

Run folder name: `<tracker-ref>-<slug>` when a tracker ref exists, otherwise a slug from the brief title.

### Branches and PR groups

PR boundaries are not planned. Phases land on a working part branch; after each phase passes review, the grouper decides from the real diff whether the PR ends there.

- Part branches follow the configured or repository branch convention; otherwise `agent/<run>-part-<nn>`. The first part bases on the integration SHA; every next part bases on the previous part's head, so parts form a stack and target the preceding part branch.
- While a part is open its name has no slug. On `CUT` the orchestrator renames it `…-part-<nn>-<slug>` and records the row in run config: phases, branch, base, target, head SHA, title, artifact folder.
- An explicit user split (recorded in run config) is passed to the grouper as a constraint.

### Each phase

1. Record phase base: part base SHA for the first phase of a part, prior phase final SHA otherwise.
2. Spawn fresh implementer with the phase section, assigned part branch, base SHA, artifact folder, verification commands, and any material findings carried from earlier phases. The implementer resolves applicable carried findings before or alongside the phase behavior and records each disposition.
3. Spawn fresh read-only reviewer with brief acceptance criteria, phase section, base/head range, commits, checks, config rules, prior reports, and carried findings. Phase review is mandatory; `PASS` requires applicable carried findings to be resolved.
4. On `NEEDS_CHANGES`, resume the same implementer, then use a new reviewer for re-review. Correct by amending/rebasing relevant commits. Add a new commit only for genuinely missing work; never add a generic review-fix commit.
5. For every phase except the final phase in the plan, allow one initial review and at most one fix/re-review cycle. If round two still returns `NEEDS_CHANGES`, keep only material findings that affect correctness, security, data integrity, acceptance criteria, or the next phase's architecture. Record them as carry-forward findings and continue; do not spend another review cycle on that phase. A finding that makes subsequent work unsafe or impossible remains a blocker.
6. The final phase has no review-round limit. Continue implementer/fresh-reviewer cycles until it passes and every material carry-forward finding is resolved. Do not finish the run with review debt.
7. Save final SHA, step-end SHAs, checks, verdict, completion note, and carry-forward findings in run config. Bind every report and finding to the reviewed SHA.
8. Spawn fresh grouper in `decide` mode with the open range, phases in it, the next phase section, carry-forward findings, and any user split. Material carry-forward findings force `STACK` so the next phase resolves them before the part closes. Otherwise act on the return:
   - `STACK` — next phase continues on the same part branch.
   - `CUT` — close the part at the phase head.
   - `CUT_AT <sha>` — close the part at that SHA; commits after it start the next part.
   If the grouper rewrote history, verify `git diff <reviewed-head> <new-head>` is empty before accepting; otherwise reject, keep the reviewed head, and re-run phase review on the grouper's head only if the user split requires that cut.

### Closing a part

On `CUT` / `CUT_AT`: rename the part branch with the grouper's slug, create the next part branch from the cut SHA, spawn fresh grouper in `describe` mode for the closed range. It writes `proposed-pr-description.md` and returns title and path; store both in run config. Never read the description. Never ask the user questions here.

### Handoff, resume, and publication

Report every part's branch, target, head SHA, phases, checks, verdicts, carry-forward state, and artifact paths. End with the exact `work-to-prs publish <run-folder>` command.

`resume` validates all saved branch/base/head state, starts a fresh implementer at the incomplete phase on the open part branch, and preserves artifacts. It never guesses state.

`publish` runs only on the explicit command, unless config's Publication timing says per-part. For each closed part bottom-to-top: validate clean state, the exact approved SHA, and an empty carry-forward list; push the branch, then execute the configured publication behavior (draft PRs, ready PRs, or push only) from saved title/body and target. If the description's Visuals section references local image paths and config names a PR image upload capability, upload each image to the new PR with it, replace the local paths with the returned URLs, and edit the PR body; without the capability, strip the local paths and note the images in the handoff. Do not publish drifted branches, open parts, fundamentally blocked work, or parts with review debt. PR titles and bodies never mention internal review rounds, verdict labels, or carry-forward state.

## Artifacts

```text
runs/<run>/
  brief.md
  phased-plan.md
  planning-dialogue.md
  run-config.md
  proposed-prs/<nn>-<slug>/
    phase-<nn>-completion.md
    phase-<nn>-review-<nn>.md
    grouping-<nn>.md
    proposed-pr-description.md
    visuals/<phase-nn>-<name>.png
```

`grouping-<nn>.md` holds the grouper's `decide` return after phase `<nn>`. `visuals/` holds uncommitted screenshots referenced by local path until publish uploads them. Retention follows config's Runs section; default keep everything. Completion notes use the repository's completion template verbatim when one exists, otherwise `templates/phase-completion.md` verbatim.
