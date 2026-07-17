---
name: verify-with-tests
description: Verify a code change (PR, branch, or current branch) by writing disposable tests and running them on both the change and its base branch. Use when the user wants to verify/prove a change works via throwaway tests, check a refactor preserved behavior, or test a PR's behavior without committing tests. Tests stay uncommitted; the user decides their fate.
---

# Verify With Tests

Verify a code change by writing disposable tests, running them on the change branch AND its base, and reporting a behavior-by-behavior verdict matrix. The tests are evidence, not deliverables: never commit them, never delete them. The user decides what happens to them after.

## Step 1: Resolve target and base

Target, in order of precedence:
1. PR number/URL in the invocation → `gh pr checkout {n}`; base = the PR's `baseRefName`
2. Branch name in the invocation → check it out; base = repo default branch
3. No argument → current branch; base = repo default branch

Repo default branch: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name` (fallback: `git symbolic-ref refs/remotes/origin/HEAD`).

Always compare at the merge-base, not base HEAD: `git merge-base origin/{base} {target}`. Base HEAD contains unrelated drift that pollutes the comparison.

Record the ref the session started on. You return to it at the end.

## Step 2: Preconditions and environment

- Tracked tree must be clean. Untracked non-code files (`.md`, notes) are nonblockers.
- Default: work in-place, switching branches in the user's working copy. Untracked test files ride along across checkouts.
- Fall back to a separate worktree only when the tree has uncommitted code changes the user wants untouched, or the user asks.
- If the lockfile differs between the two checkouts, reinstall dependencies after each switch.
- Check toolchain quirks before running anything (required node version, package manager, PATH setup).

## Step 3: Research (two parallel subagents)

Launch both in a single message:

**Evidence agent** (general-purpose) — gathers everything that hints at what to verify:
- The full diff, understood change by change
- PR description, PR comments, review comments
- Linked sources: Linear issues (linear-read skill), any URLs the PR or issue references
- The user's invocation instructions
- Returns: change classification (refactor vs behavior change), a behavior inventory, candidate edge cases, and the evidence source for each

**Harness recon agent** (Explore) — maps the testing ground:
- Existing tests touching the changed area (extend vs create decision per file)
- Test helpers and idioms the suite uses, with file paths
- How tests run (commands, config, filters) and toolchain requirements
- Returns: helper inventory, run commands, list of existing test files relevant to the change

Keep the classification sanity-check, test writing, runs, and reporting in the main conversation — those need accumulated context and user feedback.

## Step 4: Classify and state expectations

Before writing tests, state the change classification and what the dual run must show:

| Change type | Change branch | Base (merge-base) | Proves |
|---|---|---|---|
| Refactor | all green | all green | behavior preserved |
| Feature / bugfix | all green | new-behavior tests red, regression tests green | tests are not vacuous |

A mismatch in either direction is a finding, not a test bug to silence.

## Step 5: Write the tests

- Native test directories, native naming conventions — a disposable test is identified by its git status (untracked), not by where it lives. Promotion to permanent must be zero-cost.
- If a relevant test file already exists, extend it. The disposable unit is then the uncommitted diff of that file; report it as such.
- Outcome-based assertions only: observable state, returned values, emitted effects. Never assert implementation internals.
- Test at the lowest level where the behavior is observable as an outcome. Unit for pure logic, package integration for module behavior, e2e only when the behavior is visible solely through the running app — and e2e requires stating the cost and getting user confirmation first.
- Classify every enumerated behavior: **tested**, **untestable-here** (with the concrete reason: unreachable branch, wrong mode, needs e2e), or **out-of-scope** (pre-existing, untouched by the diff). Never silently narrow scope.

## Step 6: Dual run

1. Run the suite on the change branch.
2. Check out the merge-base, run the same files, check out the change branch again.
3. A test failing on the change branch: first verify the test itself is faithful to the intended behavior (fix and rerun if not — test authoring is always in scope). If the test is right, it found a bug: report it with the concrete failure scenario and leave the test red as the repro. Never fix product code, never delete or skip the test.
4. A base failure on a refactor is a behavior regression — same treatment.

## Step 7: Report

Report in chat (no docs file unless asked):

1. **Verdict matrix** — per behavior: test name, change-branch result, base result, expectation, expectation held?
2. **Untestable / skipped** — each with its reason
3. **Files** — exact paths and git status (new-untracked vs modified-tracked)
4. **Reproduction** — exact commands and toolchain used
5. Bugs found (if any), each with failure scenario

Then invite more edge cases explicitly.

## Step 8: Iterate

On user-suggested cases: extend the suite, rerun only the affected files on both branches, report the delta. Repeat until the user is done.

## Step 9: End state

- Announce: "switching back to `{original ref}` — say so if you want to stay on `{change branch}`", then act on the reply.
- Confirm final state: current branch, list of disposable files, nothing committed, nothing deleted.
- If tracked files carry uncommitted test extensions, say so explicitly.

## Hard rules

- Never commit or delete the disposable tests. The user decides.
- Never fix product code — report findings and stop.
- Never adjust a correct test to make it pass.
- Never claim "verified" for a behavior only reasoned about — the matrix contains observed runs only.
