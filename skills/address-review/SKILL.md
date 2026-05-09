---
name: address-review
description: Address PR review comments by triaging each into apply/reject/clarify, gating a plan with the human, then landing one focused commit per change with links back to the originating comments. Never comments on GitHub. Never auto-pushes. Triggers include "address PR comments", "address review feedback", "respond to PR review", "apply review comments", "go through PR comments", "work through review feedback".
---

# address-review

Take a PR's accumulated review feedback and turn it into a stack of focused, human-approved commits — one per change, each linking back to the comment(s) that motivated it.

## What this skill does NOT do

- **Never comments on GitHub.** Not on PRs, not on threads, not anywhere. The artifact and the local commit messages are the only outputs.
- **Never auto-pushes.** The skill stops at "ready to push" and waits for explicit human approval, every single time.
- **Never auto-stashes or auto-merges.** If the working tree is dirty or the branch has diverged from origin, surface and stop.
- **Never restacks downstream branches.** Different repos use different stacking tools; the skill only reminds the human to do it.

---

## Invocation

```
/address-review              # default: address comments on the PR for the current branch
/address-review <PR#>        # explicit: address comments on PR <#>; check that branch out first
```

If both forms are ambiguous (current branch maps to multiple open PRs), refuse and list them.

---

## Phase 0 — Entry-state safety

Before anything else, validate the working state:

1. **Resolve the PR.**
   - No arg: `gh pr view --json number,headRefName,headRepository,baseRefName,state,isDraft,url`
   - With `<PR#>`: `gh pr view <PR#> --json number,headRefName,headRepository,baseRefName,state,isDraft,url`
   - PR not found → surface gh's error verbatim, stop.
   - PR `state` is `CLOSED` or `MERGED` → refuse with a one-line message, stop.
   - PR head is on a fork (`headRepository.owner.login` != current repo owner) → refuse, explain v1 doesn't handle cross-fork checkout.
   - Draft PRs proceed normally.

2. **Check the working tree.**

   ```bash
   git status --short
   ```

   Any output → refuse. Print `git status --short`. Tell the human to commit / stash / discard themselves. Do **not** auto-stash.

3. **Get on the right branch.**
   - If current branch != `headRefName`, run `git checkout <headRefName>`.
   - `git fetch origin <headRefName>`
   - Compare local to `origin/<headRefName>`:
     - Strictly behind → fast-forward (`git merge --ff-only origin/<headRefName>`).
     - Strictly ahead → fine, proceed (the human has un-pushed work; that's normal).
     - Diverged (both have unique commits) → refuse, surface the divergence, stop.

4. **Establish the base SHA.**
   ```bash
   BASE_SHA=$(git merge-base origin/<baseRefName> HEAD)
   ```
   Used in Phase 2 for the idempotency walk.

---

## Phase 1 — Fetch all in-scope comments

GitHub splits review feedback across multiple endpoints. Fetch all of them; combine them into a single list.

```bash
OWNER_REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

# Inline review comments (line-anchored)
gh api "repos/$OWNER_REPO/pulls/<PR#>/comments" \
  --jq '[.[] | {id, in_reply_to_id, path, line, original_line, body, user: .user.login, html_url, created_at}]'

# Review summaries (the prose written when submitting a review)
gh api "repos/$OWNER_REPO/pulls/<PR#>/reviews" \
  --jq '[.[] | select(.body != "" and .body != null) | {id, state, body, user: .user.login, html_url, submitted_at}]'

# Top-level PR (issue) comments
gh api "repos/$OWNER_REPO/issues/<PR#>/comments" \
  --jq '[.[] | {id, body, user: .user.login, html_url, created_at}]'

# Review-thread resolution state (GraphQL — REST doesn't expose this)
gh api graphql -f query='
  query($owner:String!,$repo:String!,$num:Int!) {
    repository(owner:$owner,name:$repo) {
      pullRequest(number:$num) {
        reviewThreads(first:100) {
          nodes {
            isResolved
            isOutdated
            comments(first:50) { nodes { databaseId url body author { login } path line originalLine } }
          }
        }
      }
    }
  }' -f owner=<OWNER> -f repo=<REPO> -F num=<PR#>
```

**Inclusion rules** (substance over type — don't filter by author or bot status):

- **Include**: every inline comment, every review summary with a non-empty body, every issue comment.
- **Collapse threads**: a thread becomes one feedback candidate. Take the latest reply as the canonical ask; older replies inform context.
- **Skip**: any thread where `isResolved == true`. That's the only filter.
- **Flag, don't drop**: outdated comments (`isOutdated == true`). Show them in the triage with an `(outdated, anchor moved)` note.

Author's own self-review comments and bot comments are **kept**. Substance — not author — drives triage.

---

## Phase 2 — Idempotency: filter out already-handled comments

A re-run on a PR that's been partially addressed must not re-process the same comments.

1. **Already-applied (git is the source of truth):**

   ```bash
   git log --grep='^feedback:' --format='%H%n%B%n---' "$BASE_SHA"..HEAD
   ```

   For each `feedback:` commit body, extract every URL matching `https://github.com/.../pull/.../#.+`. Build a set of "already-applied comment URLs". Drop any fetched comment whose `html_url` is in that set.

2. **Already-rejected (artifact is supplemental):**
   If `.reviews/received/pr-<PR#>.md` exists, parse its `## Rejected` section for comment URLs. Drop those too.

If after filtering the candidate list is empty, exit cleanly:

```
No actionable comments. Nothing to do.
```

---

## Phase 3 — Triage: classify each remaining feedback

For each candidate, decide one of three dispositions using this rubric.

### Apply

All of:

- The ask is concrete (you can name the file/symbol/line that changes).
- Technically sound (won't break tests, doesn't violate documented conventions in `AGENTS.md` / `CLAUDE.md` / ADRs).
- In scope of this PR (touches code the PR already touches, or a direct dependency — e.g., updating callers of a renamed function).

### Reject

Any of:

- **Out of scope**: requires changes to code unrelated to this PR.
- **Technically wrong**: would break tests, violates a documented convention, contradicts a decision recorded in the codebase.
- **Stale**: the comment's premise no longer holds (the code it referred to was deleted/changed since).
- **Contradicted**: a later comment in the same review supersedes it.

A Reject **must cite which clause** triggered it (e.g., "Reject: out of scope — refactor of `parseConfig`, which this PR doesn't touch").

If the agent thinks the reviewer is technically wrong, it pushes back via Reject — **not** Clarify. Clarify is for things the agent doesn't know; Reject is for things the agent _has_ judged. The human can flip a Reject to Apply at plan-approval time if they disagree.

### Clarify

Anything else:

- Vague feedback ("this feels off"), multi-interpretation asks.
- Asks for a tradeoff judgment that depends on context the agent lacks (perf budgets, hot-path status, product priorities).
- More than one defensible implementation shape and the agent can't pick.

### Grouping into commits

Multiple comments often converge on the same change. Group them into **feedback items** (commit-per-theme, not commit-per-comment):

- 3 reviewers all flag the same bad name → 1 item, 3 source URLs.
- 1 comment with two unrelated asks → 2 items.

Each item has:

- **disposition**: Apply / Reject / Clarify
- **summary**: one-liner ("rename `Foo` to `Bar`")
- **source_comments**: array of comment URLs (≥ 1)
- **rationale**: why apply / why reject / what's unclear

---

## Phase 4 — Surface the high-level summary, then Q&A

Print a high-level summary first. **Don't ask per-grouping** — show the groupings here so the human can object at plan-approval if any are wrong.

Format:

```
PR #<NUM> — <title>
Fetched: <N> comments across <M> threads.
Skipping: <K> already-applied (per git log), <J> already-rejected (per artifact), <R> resolved.

After triage:
  Apply (P items): <P>
  Reject (Q items): <Q>
  Clarify (C items): <C>

Items:
  [A] Rename `Foo` to `Bar` — <url1>, <url2>
  [A] Extract `formatTime` helper — <url3>
  [R] Refactor `parseConfig` — <url4>  (out of scope)
  [C] "Should we cache this?" — <url5>
  ...
```

Then, **for each Clarify item only**, raise one question at a time using the `AskUserQuestion` tool. Each question must include:

1. The literal text of the originating comment(s).
2. The agent's interpretation of what's unclear.
3. **A recommended answer** with rationale.
4. Two-to-four concrete options.

Reject items are **not** raised as questions here — they appear in the summary, and the human can override at plan-approval. Apply items are likewise not raised individually.

Track each Clarify resolution. After the human's answer, the item moves to Apply (with revised summary) or Reject (with revised rationale), or splits into multiple items if the answer reveals two distinct asks.

---

## Phase 5 — Final plan → approval gate

After all Clarify questions are resolved, print the final consolidated plan:

```
Plan to execute:

Apply (will become commits, in this order):
  1. feedback: rename `Foo` to `Bar`
     Sources: <url1>, <url2>
     Approach: rename the type and update <N> callers in <files>.
  2. feedback: extract `formatTime` helper
     Sources: <url3>
     Approach: pull lines L–L of file.ts into a new helper in utils.ts.
  ...

Reject (no commits, recorded in .reviews/received/pr-<NUM>.md):
  - Refactor `parseConfig`
    Sources: <url4>
    Rationale: out of scope — this PR doesn't touch parseConfig.
    Paste-ready GitHub reply: "Agreed in principle, but out of scope for this PR — tracking as follow-up."
  ...

Per-commit checks: tests + typecheck + build + lint (e2e excluded)
End-of-run checks: full pre-PR sequence per AGENTS.md / CLAUDE.md
```

Ask the human: **approve as-is, edit, or abort?** Editing means the human flips dispositions (e.g., "actually apply #4") or changes orderings; the skill re-prints the plan and asks again until approved.

Only after explicit approval does Phase 6 begin.

---

## Phase 6 — Implementation loop

For each Apply item, in order:

1. **Edit** the files needed for that item only. Stay strictly in the item's scope — no incidental cleanup, no unrelated improvements.
2. **Run per-commit checks**: tests + typecheck + build + lint, **excluding e2e tests**. Use whatever the project's `AGENTS.md` / `CLAUDE.md` documents under a "Pre-PR" / "verification" section. If unspecified, infer from the package manager (e.g., for pnpm: `pnpm test --run --exclude '**/e2e/**'`, `pnpm typecheck`, `pnpm build`, `pnpm lint`).
3. **If checks fail**, attempt to fix. **Budget: 3 attempts.** If still failing after 3, halt.
4. **Commit** with this exact format:

   ```
   feedback: <one-line summary>

   Addresses:
   - <comment URL 1>
   - <comment URL 2>
   ```

   No body beyond `Addresses:`. No `Co-Authored-By` trailer. The summary line stays short and imperative.

### Halt behavior

When a halt fires (3-attempt budget exhausted, conflict, unfixable failure):

- Stop the loop. Do **not** skip-and-continue. Do **not** roll back the partial commit.
- Update `.reviews/received/pr-<NUM>.md` to reflect what completed and what blocked (see Phase 8).
- Print:
  - Which item halted.
  - What the failing check produced (last 50 lines of output).
  - What the agent tried (each fix attempt as a one-liner).
  - The diff still uncommitted, if any.
- Stop. The human takes over.

---

## Phase 7 — End-of-run full verification

After all Apply items have committed cleanly, run the **full** pre-PR sequence (lint + typecheck + build + tests, the project's documented sequence). This catches:

- Cross-commit interactions (commit 3's regression that commit 1 introduced).
- Build/declaration emit failures missed by per-commit `tsc --noEmit`.

If the final pass fails, halt the same way Phase 6 does — surface, don't auto-fix. The human investigates.

---

## Phase 8 — Write artifact, ask about push, remind about restack

### Artifact

Write `.reviews/received/pr-<PR#>.md`:

```markdown
# PR <NUM> feedback — <YYYY-MM-DD>

Branch: <headRefName>
Base SHA before run: <BASE_SHA>

## Applied

- feedback: rename `Foo` to `Bar`
  Commit: <sha>
  Sources:
  - <url1>
  - <url2>
    Rationale: concrete + sound + in-scope.

- feedback: extract `formatTime` helper
  Commit: <sha>
  Sources:
  - <url3>
    Rationale: concrete + sound + in-scope.

## Rejected (no commit)

- Refactor `parseConfig`
  Sources:
  - <url4>
    Rationale: out of scope — this PR doesn't touch parseConfig.
    Paste-ready reply: "Agreed in principle, but out of scope for this PR — tracking as follow-up."

## Clarifications resolved during triage

- Q: Should we cache `formatTime`?
  A: <human answer>
  → Became: applied / rejected / split into items 4 and 5.
```

The path `.reviews/received/` is **not** auto-gitignored by the skill; it lives alongside `.reviews/` (where you keep reviews you give to others). Existing convention.

### Push gate

Print the ready-to-push summary, then ask the human explicitly. Use `AskUserQuestion`:

> "All <N> feedback commits applied and verified. Push to `origin/<headRefName>`?"
> Options: **Yes, push now** / **No, I'll push manually** / **Show me the diff first**.

Push **only** on explicit "Yes". Even if the human said "yes, go" earlier in the session, ask again here. This gate is non-negotiable.

### Restack reminder (terminal-only)

After the push question is resolved (regardless of the answer), print one line:

> Reminder: if this PR is part of a stack, restack downstream branches/PRs now.

That's it. No specific commands — different repos use different stacking tools.

---

## Edge cases — quick reference

| Situation                                     | Behavior                                                                           |
| --------------------------------------------- | ---------------------------------------------------------------------------------- |
| PR is closed or merged                        | Refuse, exit.                                                                      |
| PR is a draft                                 | Proceed normally.                                                                  |
| PR head is on a fork                          | Refuse with explanation; v1 doesn't handle cross-fork.                             |
| No actionable comments after filtering        | Exit cleanly with "no actionable comments".                                        |
| `gh` not installed / unauthenticated          | Surface `gh`'s error verbatim; tell user to run `gh auth login`.                   |
| PR# given but doesn't exist                   | Surface `gh`'s 404; exit.                                                          |
| Current branch maps to multiple open PRs      | Refuse; list candidates; ask user to pass `<PR#>` explicitly.                      |
| Working tree dirty                            | Refuse; print `git status --short`; do not auto-stash.                             |
| Local branch diverged from origin             | Refuse; surface the divergence.                                                    |
| Local branch strictly behind origin           | Fast-forward only.                                                                 |
| Re-run after partial completion               | Phase 2 filters already-applied (git) and already-rejected (artifact).             |
| Comment was addressed manually (not by skill) | Skill will re-surface it. Human flips to Reject ("already done") at plan-approval. |

---

## Commit message format (canonical)

```
feedback: <one-line imperative summary>

Addresses:
- https://github.com/<owner>/<repo>/pull/<PR#>#<anchor>
- https://github.com/<owner>/<repo>/pull/<PR#>#<anchor>
```

- Title prefix is literally `feedback:`. No variations.
- Imperative summary (`rename`, `extract`, `inline`), not past tense.
- Body lists every contributing comment URL under `Addresses:`. ≥ 1 URL.
- No `Co-Authored-By:` trailer.
- No additional sections.
