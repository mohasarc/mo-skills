---
name: ripple-review
description: Propagate review findings from a reviewed PR forward to downstream PRs in the same stack as inline GitHub comments. Each downstream PR receives only the findings that apply to its diff, anchored to a specific file:line, tagged so they're easy to triage later. Use after reviewing a stacked PR — typically after approval and before merge — to flag repeat mistakes in subsequent PRs before reviewing them. Triggers include "ripple this review", "ripple review forward", "propagate review to downstream PRs", "flag these in subsequent PRs", "/ripple-review".
---

# ripple-review (orchestrator)

You take the review feedback already posted on a *source* PR, distill it into a small set of generalized findings, then dispatch one sub-agent per *downstream* PR in the same stack. Each sub-agent independently posts inline ripple comments on its assigned PR where the findings apply.

**You never write code.** You never edit the source PR. The only side effects this skill produces are:

1. One local Markdown file (`runs/PR-<source>/ripple-source.md`).
2. Inline GitHub review comments posted by sub-agents on downstream PRs, each tagged so they're greppable and deletable.

## What this skill does NOT do

- **Never posts top-level PR conversation comments.** Every ripple is inline (line-anchored, or file-anchored as a fallback). Conversation-tab clutter is not acceptable.
- **Never modifies the source PR.** Source comments stay where they are; this skill only reads them.
- **Never ripples a ripple.** Comments already carrying the `<!-- review-ripple: -->` tag are filtered out of the source set. Findings travel from organic comments only, once.
- **Never asks the human anything mid-run except at one gate** — the confirmation between distillation and dispatch. After that, sub-agents run autonomously.
- **Never reads local-only review output.** `/code-review` or `/ultrareview` results that were never posted to GitHub do not exist as far as this skill is concerned.

---

## Invocation

```
/ripple-review                       # default: source PR = current branch's open PR
/ripple-review <PR#>                 # explicit source PR (e.g., post-merge)
/ripple-review --to <PR#,PR#,...>    # explicit downstream override (skip stack discovery)
/ripple-review --dry-run             # distill + report what would happen; no GitHub side effects
/ripple-review --yes                 # skip the confirmation gate (for vetted re-runs)
```

Expected trigger point: after you approve the source PR, before you merge. Earlier (mid-review) misses comments that haven't landed yet; later (post-merge) loses the cross-link freshness but is supported via `<PR#>`.

---

## Phase 0 — Resolve the source PR

1. **Resolve source PR:**
   - No arg → `gh pr view --json number,headRefName,baseRefName,state,url,headRepository`. If no PR found, refuse: tell the user to pass `<PR#>` explicitly.
   - With `<PR#>` → `gh pr view <PR#> --json number,headRefName,baseRefName,state,url,headRepository`.
   - Source PR in any state is OK (open, draft, closed, merged). Merge state is irrelevant to ripple.

2. **Resolve owner/repo:**

   ```bash
   OWNER_REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
   ```

3. **Set up the run directory:**

   ```
   .claude/skills/ripple-review/runs/PR-<source>/
   ```

   If the directory already exists from a prior run, leave it in place. The skill writes a fresh `ripple-source.md` each invocation; older files in the directory are not relied upon.

---

## Phase 1 — Fetch source PR comments

Three GitHub endpoints carry review feedback. Fetch all three:

```bash
# Inline review comments (line-anchored)
gh api "repos/$OWNER_REPO/pulls/<source>/comments" \
  --jq '[.[] | {id, in_reply_to_id, path, line, original_line, body, user: .user.login, html_url, created_at}]'

# Review summaries (prose written when submitting a review)
gh api "repos/$OWNER_REPO/pulls/<source>/reviews" \
  --jq '[.[] | select(.body != "" and .body != null) | {id, state, body, user: .user.login, html_url, submitted_at}]'

# Top-level PR (issue) comments
gh api "repos/$OWNER_REPO/issues/<source>/comments" \
  --jq '[.[] | {id, body, user: .user.login, html_url, created_at}]'
```

**Thread reconstruction.** Inline comments have `in_reply_to_id`. Collapse each thread to its **root comment** (the one with `in_reply_to_id == null`); the thread's replies inform context but are not separately sourced findings.

**Filter rules applied to the combined set:**

1. **Drop ripple-tagged threads.** Any thread whose root comment body contains the literal substring `<!-- review-ripple:` is dropped. Ripples don't ripple.
2. **Drop bot acks / single-emoji reactions / pure questions answered informationally.** A short LLM classifier pass: *"Does this thread articulate a reviewable finding — something the author could have done wrong? Yes/No."* No → drop.
3. **Do not filter by author.** Self-reviews, AI-tool comments posted to GitHub, human reviewers — all kept.
4. **Do not filter by resolution status.** Resolved comments may be PR-specific; unresolved ones may be agreed-upon deferrals. Resolution is not a reliable signal for ripple-worthiness.

The output of Phase 1 is a list of thread-rooted source comments, each with: `html_url`, `path`, `line` (if inline), `body`, `user`.

---

## Phase 2 — Distill into `ripple-source.md`

Consolidate the filtered source comments into a small set of *findings*. Multiple comments expressing the same pattern collapse into one finding.

Write the result to `.claude/skills/ripple-review/runs/PR-<source>/ripple-source.md`. Structure:

````markdown
# Ripple source — PR #<source>

**Source PR:** [#<source> — <title>](<url>)
**Generated:** <YYYY-MM-DD>

---

## Finding 1: <one-line headline>

**Pattern.** <One or two sentences. Generalized statement of the rule, in code-review voice. If prose alone is insufficient, inline a short fenced code snippet here — but only when prose can't carry it.>

**Look for.** <Observable triggers a sub-agent should scan for in a diff. Concrete signals, not abstractions.>

**Source comments.**
- [PR #<source> — `<path>:<line>`](<comment url>)
- [PR #<source> — `<path>:<line>`](<comment url>)

---

## Finding 2: ...
````

**Consolidation rules:**

- One `##` section per concept. If three threads all flag "swallowing JSON.parse errors" at different sites, that's one finding with three source links.
- The `**Source comments.**` list is plural by design. Sub-agents pick the most relevant link when posting a ripple.
- Do **not** include the list of downstream PRs in the file. Sub-agents read this file as input and a downstream PR list would leak context that might distract them.
- Do not reserve slots for `example_violation` / `example_fix`. If a particular finding genuinely needs a snippet, inline it in `**Pattern.**`. Optional, not structural.

If after distillation there are **zero findings**, exit cleanly:

```
No reviewable findings extracted from PR #<source> after filtering. Nothing to ripple.
```

Do not write the file in this case.

---

## Phase 3 — Discover downstream PRs

Stack discovery is two-tiered:

1. **Graphite first.** If `gt` is available and the source branch is tracked:

   ```bash
   gt log --stack         # or: gt children, depending on gt version
   ```

   Identify all descendant branches (the source's children, grandchildren, …, to the tip). For each, resolve to an open or draft PR via:

   ```bash
   gh pr list --head <branch> --json number,state,isDraft,headRefName
   ```

2. **Base-branch fallback.** If `gt` is unavailable, untracked for the source branch, or returns nothing useful:

   ```bash
   # Recursively find PRs whose base is the source PR's head
   gh pr list --base <source-head-ref> --json number,state,isDraft,headRefName
   # Then for each of those, recurse: gh pr list --base <its-head-ref> ...
   ```

3. **Override.** If `--to` was passed, skip stack discovery entirely and use the explicit list.

**State filter.** Include open and draft PRs. Skip merged and closed.

If after discovery there are **zero downstream PRs**, exit cleanly:

```
No open or draft downstream PRs found for PR #<source>. Nothing to ripple.
```

---

## Phase 4 — Confirmation gate

Print to the terminal:

```
Distilled <N> findings from PR #<source> to:
  .claude/skills/ripple-review/runs/PR-<source>/ripple-source.md

Downstream PRs identified: <list of PR numbers and titles>

Review and (optionally) edit ripple-source.md, then reply `go` to dispatch sub-agents.
Or run `/ripple-review --yes` to skip this gate on a vetted re-run.
```

Stop. Wait for the human.

- If `--yes` was passed initially, skip this phase entirely and go straight to Phase 5.
- If `--dry-run` was passed initially, print the same summary plus a line saying *"Dry run — no sub-agents dispatched, no comments posted."* and exit cleanly.

When the human replies `go` (or any clear affirmative), re-read `ripple-source.md` from disk — not from memory. Their edits are the source of truth. If they removed findings, those are gone; if they edited wording, sub-agents see the new wording.

---

## Phase 5 — Dispatch sub-agents

For each downstream PR, spawn a sub-agent via the `Agent` tool with `subagent_type: general-purpose`. Run them concurrently — one tool block, multiple Agent calls.

Each sub-agent's prompt is built from a fixed template:

```
You are a ripple-review sub-agent for one downstream PR.

Your runbook is at:
  .claude/skills/ripple-review/subagent.md

Read it first, then follow it.

Inputs:
  ripple-source.md: <absolute path>
  downstream PR:    <PR#>
  owner/repo:       <OWNER_REPO>
  source PR:        <source PR#>  (for the link-back tag)

Return a JSON summary on your final line in this shape:
  {"pr": <PR#>, "posted": <N>, "matches": [{"finding": "<headline>", "path": "<path>", "line": <line or null>, "comment_url": "<url>"}, ...], "skipped": <K>, "errors": []}
```

Sub-agents post inline comments directly on GitHub. You do not relay or proxy their posts.

**Do not read sub-agent transcripts** beyond the final JSON line. Context discipline matters: keep your own context small so you can summarize the whole run cleanly.

---

## Phase 6 — Final report

After all sub-agents return, print a single consolidated summary:

```
Ripple complete.

Source: PR #<source> (<N> findings distilled)
Dispatched to: <M> downstream PRs

PR #43 — <title>: 3 ripples posted
  - Finding 1 (`parseConfig` swallows JSON.parse errors) at src/config.ts:18
  - Finding 1 at src/loader.ts:44
  - Finding 4 (missing null check on lookup) at src/utils.ts:88
PR #44 — <title>: 0 ripples posted (no applicable findings)
PR #45 — <title>: 2 ripples posted
  - Finding 2 at src/migrate.ts:99
  - Finding 6 at src/db.ts:12
PR #46 — <title>: 1 ripple posted
  - Finding 3 at src/auth.ts:5

Total: 6 comments posted across 4 PRs.

ripple-source.md retained at:
  .claude/skills/ripple-review/runs/PR-<source>/ripple-source.md
```

If any sub-agent errored, list its errors verbatim under its PR line. Do not retry — the human investigates.

---

## Edge cases — quick reference

| Situation                                              | Behavior                                                                |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| No arg + current branch has no open PR                 | Refuse; tell user to pass `<PR#>`.                                      |
| No arg + current branch maps to multiple open PRs      | Refuse; list candidates; ask user to pass `<PR#>`.                      |
| Source PR doesn't exist                                | Surface `gh`'s error verbatim; exit.                                    |
| Source PR has no reviewable comments after filtering   | Exit cleanly with "nothing to ripple". Do not write the file.           |
| No downstream PRs found via either discovery method    | Exit cleanly with "no downstream PRs".                                  |
| `gt` not installed                                     | Fall through to base-branch discovery silently.                         |
| `gh` not installed / unauthenticated                   | Surface `gh`'s error; tell user to run `gh auth login`.                 |
| Run directory already exists from prior run            | Overwrite `ripple-source.md`. Do not delete other files in the dir.     |
| Human edited `ripple-source.md` to remove all findings | After `go`, re-read file; if zero findings, exit cleanly.               |
| Sub-agent fails / times out                            | Report its failure in the final summary; do not retry.                  |
| Concurrent re-run on same source PR                    | Sub-agents' mechanical de-dup (9a in runbook) prevents duplicate posts. |

---

## What you never do

- Write code, edit source files, or modify the source PR's comments.
- Post comments yourself — only sub-agents post.
- Post top-level conversation comments on any PR.
- Read sub-agent transcripts beyond the final JSON line.
- Retry failed sub-agents automatically.
- Bulk-delete existing ripples. The user triages in the GitHub UI.
- Skip the confirmation gate unless `--yes` was explicitly passed.
