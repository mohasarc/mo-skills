# trace-code-flow

Agent skill for understanding codebase flows.

Use it when you are in an unfamiliar part of a repo and do not want a detailed architecture doc. You just want the high-level flow.

Example prompts:

> explain how password reset works

or:

> explain this PR change in context

The skill traces relevant code paths, follows calls/events/async re-entry points, cuts through layers that do not matter for the main path, and writes the result as pseudo-code.

The output is meant to be boring. Mostly numbered comments and simple pseudo-code.

This format often works better than normal summaries for complicated code. Pseudo-code is compact, keeps order visible, and removes language syntax noise.

Find it here:

https://www.skills.sh/mohasarc/mo-skills/trace-code-flow

Install:

```bash
npx skills add mohasarc/mo-skills --skill trace-code-flow
```
