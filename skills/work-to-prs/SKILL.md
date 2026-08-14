---
name: work-to-prs
description: Take any work item — tracker issue, URL, or plain text — through private two-agent planning, phased TDD implementation, strict review, local PR artifacts, and explicit configurable publication. Use when the user wants a work item implemented end to end, wants PR proposals prepared, or asks to resume or publish from this workflow.
---

# Work to PRs

Implement any work item end to end. Complexity is not a gate. Nothing is published without the explicit `publish` command.

This workflow owns its implementation and review rules. Its methods are bundled under `methods/`; do not use or read outside implementation-orchestration or review skills for its rules.

## Modes

| Invocation | Behavior |
| --- | --- |
| `work-to-prs <tracker ref, URL, or free text>` | Research, plan, implement, review, and create local artifacts. Never push or publish. |
| `work-to-prs resume <run-folder>` | Validate durable state and continue incomplete work. |
| `work-to-prs publish <run-folder>` | Execute the publication behavior set in `config.md`. |

Never infer `publish` from an implementation request. Before doing anything, `publish` prints one line stating exactly what it is about to do (e.g. "opening 2 draft PRs targeting development").

## Config

`config.md` beside this file is the project rules file. Read it at preflight. Its Extra guidance rules pass verbatim to every agent. For unset Conventions values, discover from repository docs; after a successful run, offer to record discovered values into `config.md` and write only after the user agrees.

## Capabilities

Input access and optional tooling come from the project, not this skill. Use what `config.md` names: tracker access (project skill, MCP, or CLI), code navigation, video links, PR tree embeds. If input references a tracker and no access method is configured or discoverable, stop with a clear report. Treat the tracker as read-only unless config says otherwise.

## Agents

Spawn subagents natively through the harness, passing the role's runbook file and the model hint from config's Models section. Unset hints mean harness default; an unavailable hint falls back to default and is noted in the handoff. If the harness cannot spawn subagents, play the roles sequentially in one context and disclose the lost context isolation in the handoff.

## Boundaries

- Run phases and reviews sequentially.
- Never push, create PRs, merge, delete, stash, or discard work in implementation mode.
- Stop if user-owned working-tree changes exist. `runs/` is git-ignored; never force-add it.
- Preserve branches and artifacts after all outcomes.
- Orchestrator reads only the brief, phased plan, run config, git status, completion notes, and review verdicts. Never read planning dialogue, subagent transcripts, or implementation code.

## Workflow

### Preflight and planning

1. Read `config.md`. Classify input: configured tracker reference, or free text used as the work description. Read repository instructions for unset conventions: integration branch, branch convention, PR templates, verification commands. Use the documented integration branch or `development`, then `main`.
2. Confirm working tree has no user-owned changes. Update base only as repository rules allow and record base SHA. Do not update it mid-run.
3. Spawn planner with `planner.md`; planner alone spawns companion with `companion.md`. Orchestrator never receives their messages.
4. Planner writes `runs/<run>/brief.md`, `phased-plan.md`, and `planning-dialogue.md`. It returns only plan path, phase count, PR grouping recommendation, and material assumptions.
5. Create `run-config.md` from `templates/run-config.md`, recording the work reference, base SHA, branch convention, and commands.

Run folder name: `<tracker-ref>-<slug>` when a tracker ref exists, otherwise a slug from the brief title.

### Branch groups

Apply explicit user split first. Otherwise, one branch/PR is default; split only at independently reviewable/releasable boundaries. Planner recommends grouping; orchestrator records final choice.

Record every group's phases, branch, base branch/SHA, target, artifact folder, and title. Follow the configured or repository branch convention; otherwise use `agent/<run>` and `-part-<n>` suffixes. Independent PRs target the integration branch. Stacks target the preceding group branch.

### Each phase

1. Record phase base: group base SHA for first phase, prior phase final SHA otherwise.
2. Spawn fresh implementer with the phase section, assigned branch, base SHA, artifact folder, and verification commands.
3. Spawn fresh read-only reviewer with brief acceptance criteria, phase section, base/head range, commits, checks, config rules, and prior reports.
4. On `NEEDS_CHANGES`, resume the same implementer, then use a new reviewer for re-review. Correct by amending/rebasing relevant commits. Add a new commit only for genuinely missing work; never add a generic review-fix commit.
5. Allow initial review plus three fix/re-review cycles. Remaining findings become `BEST_EFFORT` and the next phase continues. Reviewer identifies fundamental blockers with evidence; orchestrator stops only if the next phase is unsafe or impossible.
6. Save final SHA, checks, verdict, completion note, and unresolved findings in run config.

Implementers can refine commit sequence when discovery makes history cleaner, but preserve phase behavior, TDD, and commit hygiene. Never push.

### Final PR artifacts

After group phases complete, use a fresh final reviewer for group base → head: cross-phase interactions, scope, test evidence, history, description readiness, and target branch. Apply the same correction and best-effort rules.

Orchestrator writes each `proposed-pr-description.md` from completion notes, final review, checks, work-item link, metadata, and the dominant matching repository PR template. Use `templates/pr-description.md` only if no repository template fits. Store title in run config. Never ask the user questions here.

### Handoff, resume, and publication

Report every group's branch, target, head SHA, phases, checks, final verdict, unresolved findings, and artifact paths. End with the exact `work-to-prs publish <run-folder>` command.

`resume` validates all saved branch/base/head state, starts a fresh implementer at the incomplete phase, and preserves artifacts. It never guesses state.

`publish` runs only on the explicit command, unless config's Publication timing says per-group. For each group bottom-to-top: validate clean state and the exact approved SHA, push the branch, then execute the configured publication behavior (draft PRs, ready PRs, or push only) from saved title/body and target. Do not publish drifted branches. A `BEST_EFFORT` PR may open only here and must disclose unresolved findings. Fundamentally blocked work must resume first.

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
    final-review.md
    proposed-pr-description.md
```

Retention follows config's Runs section; default keep everything. Completion notes use the repository's completion template verbatim when one exists, otherwise `templates/phase-completion.md` verbatim.
