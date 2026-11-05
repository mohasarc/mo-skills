---
name: scaffold-project
description: Set up a new or existing project folder with Mo's agent setup — AGENTS.md, rules, and a basic set of skills plus extras chosen for the project. Use when the user wants to start a new project, scaffold a project, or add their agent setup to a folder.
---

# Scaffold a project

Set up the agent environment for a project. Do not build the project itself here.

## 1. Learn what the project needs

Answer these from the user's message and the folder first. Ask only what's left, one question at a time:

- What is it, and who is it for?
- Where does it go? An existing folder if the user is in one or names one; otherwise under `~/dev/`:
  - `ventures/` startup ideas
  - `projects/` serious side projects
  - `playground/` throwaway
  - `work/<company>/` employer work
- Is it TypeScript?
- How will work land? Solo on `main`, or through reviewed PRs?
- Any tracker or video links involved (Linear, Loom)?

## 2. Choose the skills

The basic set in `basic-skills.txt` is always included. Run this to see every available skill, then pick extras only when the project clearly needs them:

```bash
scripts/scaffold.sh --list
```

Rough guide:

| Project needs | Extras |
|---|---|
| Reviewed PRs | `address-review`, `ripple-review`, `propagate-feedback-fixes` |
| Agents implementing large work end to end | `work-to-prs` |
| Existing code to understand | `trace-code-flow`, `document-feature` |
| Linear tickets | `linear-read` |
| Loom videos | `loom-watch` |

Throwaway projects usually need no extras. Judge skills not in this table by their descriptions. Show the user the chosen extras with a one-line reason each, and wait for their okay.

## 3. Run the scaffold

Resolve `scripts/` relative to this file:

```bash
scripts/scaffold.sh <target-dir> [--typescript] [--skill <name>]... [--no-skill <name>]...
```

`--typescript` adds the symnav rule and skill. `--no-skill <name>` leaves out a basic skill. The script only adds what's missing and reports what it kept. `.agents/scaffold-manifest` records what was added, so a rerun doesn't restore anything removed since. `--skill <name>` brings a removed skill back; for a rule, delete its line from the manifest. If it kept an `AGENTS.md`, `CLAUDE.md`, or `.claude/` entry that isn't the expected link, tell the user instead of changing it.

## 4. Fill in the project specifics

- Replace the `{{...}}` placeholders in `AGENTS.md` with what you learned. Don't invent commands; say there are none yet.
- If `work-to-prs` was included, update its `config.md` in the project: `Tracker` when there is one, `Code navigation: symnav` for TypeScript, and the integration branch. Leave publication rules at their defaults unless the user asks.
- Add stack-specific lines to `.gitignore` only if the stack is already known.

## 5. Finish

- Don't commit, create a GitHub repo, or push unless the user asks.
- Report the folder, the extras chosen, and anything kept instead of added.
- Tell the user to start a new agent session in that folder. Skills and rules load at session start, so this session won't have them.
