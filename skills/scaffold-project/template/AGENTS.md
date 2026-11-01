# {{PROJECT_NAME}}

## What this is

{{ONE_OR_TWO_SENTENCES: what it does and who it's for}}

## Commands

{{INSTALL_BUILD_TEST_LINT_COMMANDS, or "None yet — add them as soon as the project has them."}}

## How we work

- Rules live in `.agents/rules/` and skills in `.agents/skills/`.
- Project-specific skills end in `+` (e.g. `.agents/skills/deploy+/`) and are committed. The others are copied from mo-skills and gitignored.
- Keep this file short. Add a fact here only when an agent would otherwise get it wrong.
