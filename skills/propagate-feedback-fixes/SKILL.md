---
name: propagate-feedback-fixes
description: Restack downstream stacked PRs and apply the current PR's reviewer feedback in their code.
---

Feedback was applied on current branch. Downstream stacked PRs may repeat the mistake or depend on old shape of changed code. Restack and fix them, one subagent per branch, sequential bottom-up. Stacking-tool agnostic.

- Infer feedback from feedback commits, session context, PR comments. Applied only; rejections don't always have a comment.
- Main agent passes each subagent a brief: each feedback item + how current branch fixed it.
- Subagent rebases its branch onto updated parent, resolves conflicts, applies feedback only where branch repeats old pattern or consumes changed code. No broad rewrites.
- No feedback commits downstream: fold into the commit each change belongs to, per commit rules. Add/drop commits only if clean history requires.
- Verify per branch: typecheck + affected tests.
- Push current branch immediately. Push downstream once, together, after full cascade succeeds.
- Subagent stuck (conflict, ambiguous feedback) → abort its rebase, stop cascade, report done branches + blocker. Nothing downstream pushed.
