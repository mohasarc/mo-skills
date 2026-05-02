---
name: implement-phase
description: Guides the agent in implementing a single phase from a phased implementation plan document. Use when the user asks to implement a specific phase, execute a step from a plan, or work on a phased plan.
---

# Implementing a Phased Plan

When asked to implement a specific phase from a phased implementation plan document, follow this strictly constrained workflow.

## 1. Context Gathering

Before writing any code:

1. **Read the Plan**: Read the provided phased plan document to understand the requirements and the detailed implementation plan. It is your bible.
2. **Review Progress**: Check the changes made so far to understand the context of the current phase. Generally, each commit refers to one phase.
    - Use `git --no-pager log --oneline` to see the recent commit history.
    - Use `git --no-pager show <commit-hash>` to see the exact changes made in a specific previous phase.
    - To automatically determine the base branch and see all commit messages, use:
      `git --no-pager log $(git for-each-ref --format='%(refname)' refs/heads/ refs/remotes/ | grep -v "$(git rev-parse --abbrev-ref HEAD)" | xargs -n 1 git merge-base HEAD | sort -u | xargs -n 1 git log -1 --format="%at %H" | sort -nr | head -1 | awk '{print $2}')...HEAD --pretty=format:"%C(yellow)%h%Creset %C(green)%s%Creset %C(blue)(%cr)%Creset %C(cyan)<%an>%Creset"`.
    - To automatically determine the base branch and see all unmerged changes, use:
      `git --no-pager diff $(git for-each-ref --format='%(refname)' refs/heads/ refs/remotes/ | grep -v "$(git rev-parse --abbrev-ref HEAD)" | xargs -n 1 git merge-base HEAD | sort -u | xargs -n 1 git log -1 --format="%at %H" | sort -nr | head -1 | awk '{print $2}')...HEAD`

## 2. Implementation Rules

When implementing the requested phase, you MUST adhere to these rules:

1. **Strictly Scope Changes**: All code changes must belong ONLY to the requested phase. You must not make any changes related to another phase.
2. **Keep it Minimal**: Keep the changes clean and minimal. You must not change things for no reason, and you must not perform meaningless refactors.
3. **Test Your Changes**: Make sure to add unit tests for all the changes you make. Use these tests to verify that your changes work as expected. You may skip unit tests if the changes are very minimal or already tested.
4. **DO NOT Commit**: You MUST NOT commit anything. The user will perform the committing themselves.

## 3. Completion Steps

Once the implementation for the phase is done, provide a response to the user with the following structure:

1. **Summary**: Summarize the changes you made and the reasoning behind them.
2. **Verification Instructions**: Explain to the user how they can verify the changes themselves. This could be manual testing steps, QA procedures, or pointing out certain design decisions they should review.
3. **Commit Message Suggestion**: Suggest a commit message split into two parts that the user can paste or run.
    - **TL;DR (subject line)**: One very short line—what landed, no fluff. This becomes the first paragraph of `git log` and should read well alone.
    - **Summary (body)**: A few sentences (not a wall of text) that add context: what changed, why it matters for this phase, and any notable tradeoffs or follow-ups. Still tight; prefer bullets or short clauses over prose essays.
    - **Format**: Show both parts in a plain text block (label TL;DR vs Summary), then a bash code block with `git commit -m "<TL;DR>" -m "<Summary>"` (escape quotes inside strings as needed).
