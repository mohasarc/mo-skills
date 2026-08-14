# Work-to-PRs Rules

## Reading work items
How the orchestrator turns your input into a brief.
- Tracker: none. Plain text is used as the work description; tracker references trigger discovery of the project's access skill/MCP.

## Models
Model per agent role; harness picks defaults for unset roles.
- Planner: default
- Companion: default
- Implementer: default
- Reviewer: default

## Publication
What the `publish` command does. Implementation runs never push or open PRs by themselves.
- Open draft PRs. (alternatives: open ready-for-review PRs / only push branches)
- Publish all groups together when `publish` is run. (alternative: publish each group as soon as it passes final review)

## Runs
Where run output lives (brief, plan, dialogue, reviews, completion notes, proposed PR descriptions).
- Folder: runs/ inside this skill folder, one subfolder per run, git-ignored.
- Retention: keep everything.

## Conventions
Repo facts. Discovered from repo docs when unset; the agent asks before writing them here.
- Integration branch: discover
- Branch naming: discover
- Verification commands: discover

## Capabilities
Tools agents may use when configured.
- Code navigation: none
- Video links: none
- PR tree embeds: none

## Extra guidance
Freeform rules passed verbatim to every agent. Rules here override the workflow's defaults.
- (none)
