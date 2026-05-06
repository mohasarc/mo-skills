---
name: stack-prs-manual
description: Use when working with stacked PRs by hand (no Graphite, no GitHub stacking app) — branches whose PRs target another open PR's branch instead of `development`. Triggers: branching off an in-review branch, asking to stack/restack/propagate/retarget, pushing commits to a branch with open downstream PRs, asking for stack status. Skip for ordinary single-PR work whose base is `development`.
---

# stack-prs-manual

A behavioral rulebook for working with stacked PRs using only `git` and `gh`. The agent infers intent from context and proactively proposes the next action — there are no commands to memorize.

## Mental model

A **stack** is a chain (or tree) of branches where each branch's PR targets the previous branch's PR instead of `development`. The bottom of a stack — the **stack root** — has its PR targeting `development` like normal.

**Topology is derived dynamically.** The source of truth is each PR's `baseRefName`. There is no local state file. To find the stack:

- **Walk up** from any branch: `gh pr view <branch> --json baseRefName` → if `baseRefName != development`, recurse on the parent. Stop at `development`.
- **Walk down**: `gh pr list --base <branch> --state open --json number,headRefName,baseRefName` → recurse on each child. Branching trees are allowed (one parent, many children).

**The rebase contract — and its exception.** Restacks default to `git rebase` with `--force-with-lease`. Reviewers of stacked **draft** PRs are warned upfront, in the auto-maintained stack comment, that downstream branches will be force-pushed when upstream lands and inline review comments may go "outdated"; reviewing a stacked draft PR means accepting that contract.

**Once a PR has received a review** (any submitted review — `COMMENTED`, `APPROVED`, or `CHANGES_REQUESTED`), the contract flips: **do not rewrite its history**. To bring fresher upstream into a reviewed branch, use `git merge`, not `git rebase`, so existing inline review anchors stay live. New commits on top remain fine — they're additive, not history-rewriting. The rebase path applies only to branches whose PR is still draft and unreviewed.

This matters most for **stack roots**, which typically collect reviews while downstream draft branches are still in flight. Once a root is reviewed, it can only be **merged-into**; the cascade still rebases unreviewed downstream drafts as usual. Check review state with `gh pr view <branch> --json reviews --jq '.reviews | length'` before deciding rebase vs merge.

## Detecting intent

The agent reads the situation and proposes the right action:

- On `development` with uncommitted changes and the user signals new work → propose creating a new branch (this will be a **stack root**; nothing stack-specific happens until a downstream branch is added).
- On a branch whose PR's base is another branch (or whose branch already has one or more downstream PRs), with uncommitted changes and the user signals new work → propose a **downstream branch** off the current one.
- New commits land on a branch that has downstream PRs (open) → propose a **cascade restack** of the downstream subtree (per-child, rebase if the child's PR is unreviewed-draft, merge if it has any review).
- The user wants fresher upstream content in a branch whose PR has received any review → propose **merge** (`git merge origin/<base>`), never rebase. Force-push is forbidden once a PR has been reviewed.
- An upstream PR was merged to `development` (detected via `gh pr view <upstream> --json state,mergedAt,headRefOid`) and the immediate downstream's base still points at the merged branch → propose **retarget**: rebase `--onto development` using the merged PR's `headRefOid`, change base to `development`, mark ready for review (un-draft). Only valid when the immediate downstream is still draft/unreviewed; if it has reviews, retarget via `gh pr edit --base development` and `git merge origin/development` instead.
- The user asks for stack status → walk topology and print the tree.

Always **ask before** taking destructive actions (force-push, rebase). Cascade confirmation is **once per cascade**, not per branch. Inside an approved cascade, force-push is silent except on lease failure.

## Working tree

Default: refuse to start any stack operation if `git status --porcelain` is non-empty. Offer to `git stash push -u` with explicit user confirmation. Only `git stash pop` if the operation completed fully; if it stopped on conflict, leave the stash and tell the user `git stash list` shows it.

## PR conventions

- **Stack root PR** (`base == development`): not draft. Hidden marker in the PR body: `<!-- stack-skill:root -->` plus a brief "do not delete; tracks this PR as the bottom of a stack" note. Marker is decorative; lineage is the source of truth.
- **Downstream PR** (`base != development`): always opened as **Draft** via `gh pr create --draft --base <parent-branch>`.
- **Stacked-on comment** is posted on every PR in the stack on PR open and updated on every topology change. See template below.
- **PR body follows the repo's PR template** when one exists. Check `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `PULL_REQUEST_TEMPLATE.md`, and `docs/pull_request_template.md`. If multiple templates exist, pick the one that fits the change. Fill in narrative sections (Summary, Context, etc.). **Do not tick user-action checkboxes** like `- [ ] Tested locally` or `- [ ] Added tests` — leave them as `[ ]` for the user to confirm; the agent has not personally satisfied those items. The hidden root marker (for the root PR) goes at the very bottom, below the template body. If no template exists, fall back to a minimal description.

## The stacked-on comment

A single bot-style comment, identified by a hidden HTML marker so the agent finds and updates the same comment instead of posting new ones each time.

```markdown
<!-- stack-skill:auto -->
**Stacked PR** — _automated comment, posted on the author's behalf_

This PR is stacked on top of #<parent-pr> and should only be merged after #<parent-pr> is merged.

**Stack:**
1. #<root-pr> ← merged ✓
2. #<intermediate-pr> ← in review (was stacked on #<root-pr>, now targets `development`)
3. **#<this-pr> ← you are here**
4. #<downstream-pr> ← draft, stacked on this

⚠️ **Heads-up to reviewers:** this branch will be rebased and force-pushed when an upstream PR lands. Inline review comments may be marked "outdated" and lose their original line anchor; PR-level (issue) comments are unaffected. If you want a stable target for inline review, wait until this PR's base becomes `development`.
```

Status tags rendered next to each entry: `merged ✓`, `in review`, `draft`, `you are here` (bolded). **Merged ancestors stay in the list**, marked `merged ✓`, so reviewers retain historical context — they're not dropped just because they no longer have downstream effect.

Find the existing comment:
```bash
gh api repos/:owner/:repo/issues/<pr-number>/comments \
  --jq '.[] | select(.body | contains("stack-skill:auto")) | .id'
```

Update via `gh api -X PATCH /repos/:owner/:repo/issues/comments/<comment-id> -f body=...`.

The "Stack:" rendering is a tree when there are siblings: indent children under their parent, mark the current PR with **bold**. Update the comment on **every open PR in the stack** any time topology changes. Skip closed/merged PRs.

## Workflow: starting a downstream branch

User is on a branch with a PR (call it `parent`), wants to start work that builds on it.

1. Confirm working tree is clean (or stashed with consent).
2. `git checkout -b <new-branch>` (name from the user; this skill does not enforce naming).
3. User makes commits as normal.
4. When ready to push: `git push -u origin <new-branch>`.
5. Open PR: `gh pr create --draft --base <parent> --title "..." --body "..."`.
6. Post the stacked-on comment on the new PR.
7. Update the stacked-on comment on every other open PR in the stack to include the new node.

## Workflow: bringing fresher upstream into a single branch (no downstream)

The user wants to update one branch with new commits from its base (e.g. `development` shipped the API change you depend on). The path forks on review state:

```bash
gh pr view <branch> --json reviews --jq '.reviews | length'
```

- **`0` reviews** (draft, never reviewed) → **rebase** path:
  1. `git fetch origin <base>`
  2. `git rebase origin/<base>` (resolve any conflicts manually — never auto-resolve)
  3. `git push --force-with-lease`
- **`> 0` reviews** (any submitted review) → **merge** path:
  1. `git fetch origin <base>`
  2. `git merge origin/<base>` (resolve any conflicts manually)
  3. `git push` (plain push — never `--force`)

The merge commit is fine; the repo squash-merges PRs at land time, so it disappears from `development`'s history anyway. Inline review anchors stay live because no history is rewritten.

## Workflow: cascade-restacking downstream after upstream changes

User pushed new commits to `parent` (review feedback or a merge from base) while `parent` is still open. Children are stale.

1. Walk down from `parent` to enumerate open downstream PRs in topology order (BFS).
2. **For each child, check review state** (`gh pr view <child-branch> --json reviews --jq '.reviews | length'`). The child's path depends on its own review state, not the parent's:
   - `0` reviews → **rebase** path (force-push needed).
   - `> 0` reviews → **merge** path (no force-push).
3. List the cascade plan to the user — flag which children will be force-pushed (rebase) vs. plain-pushed (merge) — and ask once for confirmation.
4. For each downstream `child` in order:
   1. `git fetch origin <parent-branch>`
   2. `git checkout <child-branch>`
   3. **Rebase path** (unreviewed child): `git rebase origin/<parent-branch>` then `git push --force-with-lease`. If the lease fails, stop and ask — never plain `--force`.
   4. **Merge path** (reviewed child): `git merge origin/<parent-branch>` then `git push` (plain).
   5. On conflict (either path): stop, do **not** auto-resolve. Summarize which files conflict and which commits are involved. Tell the user the standard `git rebase --continue / --abort` (or `git merge --continue / --abort`) flow. Leave the cascade in a partially-restacked state; agent reports `✓ d1 ✗ d2 ⏸ d3 d4` and waits for the user to resolve and re-invoke.
   6. After the child is updated, walk into its own children and repeat.
5. After cascade: refresh the stacked-on comment on every open PR.

## Workflow: retargeting after an upstream merges to development

The repo squash-merges PRs (verified: `mergeCommitAllowed: true`, `squashMergeAllowed: true`, `rebaseMergeAllowed: false`; the auto staging→development merges in first-parent log are not PR merges). After squash-merge, the upstream branch's individual commits are **not** in `development`; only one squashed commit is. Plain `git rebase development` will conflict because git tries to replay the orphaned commits against the squashed equivalent.

The fix uses `--onto` with the merged PR's preserved `headRefOid`. Note the **ordering**: an upstream may have received new commits just before merging, so the stack below it may be stale relative to the merged tip. Always restack the stack onto the latest pre-merge tip *first*, then retarget. This guarantees downstreams are correctly aligned on the same content `development` now contains, and avoids mixed-state cascades.

1. Detect: `gh pr view <upstream-pr> --json state,mergedAt,headRefOid` returns `state == "MERGED"`.
2. Capture `headRefOid` (call it `OLD_TIP`). GitHub preserves this on the PR record forever, even after the branch is deleted.
3. **Restack the stack onto `OLD_TIP` first** (not onto `development`). This is a normal cascade restack from the immediate downstream and walks the whole subtree, using plain `git rebase <OLD_TIP>` against the captured SHA (the upstream branch may already be deleted on the remote, so use the SHA, not the branch name). After this step, every downstream is correctly stacked on the exact content that was merged.
4. `git fetch origin development`
5. `git checkout <immediate-downstream-branch>`
6. `git rebase --onto origin/development <OLD_TIP>` — drops the merged upstream's commits and replays only the immediate downstream's own commits on top of `development`.
7. On conflict: same UX as cascade conflict (stop + summarize + wait).
8. `git push --force-with-lease`
9. `gh pr edit <downstream-pr> --base development` — switch the PR base.
10. `gh pr ready <downstream-pr>` — un-draft. This PR is now the new stack root and ready for review.
11. Cascade-restack the rest of the subtree below the just-retargeted branch. Plain rebase suffices from this point; the squash-merge issue only applies at the merge boundary itself.
12. Refresh stacked-on comments on **every open PR in the stack**. The retargeted branch is now a stack root, but its comment **keeps the merged ancestor** in the "Stack:" list, marked `merged ✓`, so reviewers retain historical context. Add a one-line note at the top of the retargeted branch's comment: `✅ Upstream #<merged-pr> has been merged. This PR now targets \`development\` and is ready for review.` The note is removed on the next comment refresh after reviewers have had a chance to see it (e.g. once any new review activity occurs), so it doesn't accumulate.

## Hard rules

- Never `git push --force` without `--lease`. If the lease fails, stop and ask.
- **Never rewrite history on a PR that has received any review** (`COMMENTED`, `APPROVED`, or `CHANGES_REQUESTED`). Use `git merge` to bring in upstream; new commits on top are fine. The rebase + force-push contract applies only to draft, unreviewed PRs. Always check `gh pr view <branch> --json reviews --jq '.reviews | length'` before any rebase that brings in upstream changes.
- Never rewrite history on a branch that does not belong to the user's current stack.
- Never auto-resolve rebase conflicts. Always stop, summarize, hand back to the user.
- Never run a stack operation with a dirty working tree unless the user has consented to a stash.
- Never silently `git stash drop` when a cascade fails partway.
- Never invent stack topology from branch names. Lineage comes from PR `baseRefName` only.
- Never post a duplicate stacked-on comment. Always find the existing one via the `stack-skill:auto` marker and update it.
- Never run any of the above without an explicit single up-front confirmation from the user for each cascade or retarget.

## Tools

- `gh pr view <branch-or-num> --json number,state,baseRefName,headRefName,headRefOid,mergedAt,isDraft`
- `gh pr list --base <branch> --state open --json number,headRefName,baseRefName`
- `gh pr create --draft --base <parent> --title ... --body ...`
- `gh pr edit <num> --base development`
- `gh pr ready <num>`
- `gh api repos/:owner/:repo/issues/<num>/comments` (find/update the auto comment)
- `gh pr view <branch> --json reviews --jq '.reviews | length'` (gate rebase vs merge — `0` allows rebase, `>0` requires merge)
- `git rebase origin/<parent>` (cascade onto unreviewed-draft child)
- `git merge origin/<parent>` (cascade onto reviewed child, OR pull fresher upstream into a reviewed branch — no force-push afterward)
- `git rebase --onto origin/development <OLD_TIP>` (post-merge retarget, only valid if downstream is unreviewed)
- `git push --force-with-lease` (rebase path only)
- `git push` (merge path — plain push)
- `git stash push -u` / `git stash pop`
