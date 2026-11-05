#!/bin/bash
# Adds the agent setup to a project folder. Only adds what's missing; never overwrites.
#   scaffold.sh --list
#   scaffold.sh <target-dir> [--typescript] [--skill <name>]... [--no-skill <name>]...
set -euo pipefail

SELF="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
SKILLS_ROOT="$(dirname "$SELF")"
TEMPLATE="$SELF/template"
SYMNAV_REPO="${SYMNAV_REPO:-$HOME/dev/projects/symnav}"

skill_dir() {
  local found
  found=$(find "$SKILLS_ROOT" -type f -name SKILL.md -path "*/$1/SKILL.md" -not -path '*/node_modules/*' | head -1)
  if [ -z "$found" ] && [ "$1" = symnav ] && [ -f "$SYMNAV_REPO/skills/symnav/SKILL.md" ]; then
    found="$SYMNAV_REPO/skills/symnav/SKILL.md"
  fi
  [ -n "$found" ] && dirname "$found"
}

list_skills() {
  find "$SKILLS_ROOT" -type f -name SKILL.md -not -path '*/node_modules/*' -not -path "$SELF/*" |
    while read -r file; do
      printf '%s: %s\n' "$(basename "$(dirname "$file")")" \
        "$(awk '/^description:/{sub(/^description: *"?/,""); print; exit}' "$file")"
    done | sort
}

is_listed() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

if [ "${1:-}" = --list ]; then list_skills; exit 0; fi
[ $# -ge 1 ] || { sed -n 3,4p "$0"; exit 2; }

TARGET="$1"; shift
TYPESCRIPT=0
SKILLS=()
EXPLICIT_SKILLS=" "
EXCLUDED_SKILLS=" "
while read -r name; do SKILLS+=("$name"); done < "$SELF/basic-skills.txt"
while [ $# -gt 0 ]; do
  case "$1" in
    --typescript) TYPESCRIPT=1; SKILLS+=(symnav); shift ;;
    --skill) SKILLS+=("$2"); EXPLICIT_SKILLS="$EXPLICIT_SKILLS$2 "; shift 2 ;;
    --no-skill) EXCLUDED_SKILLS="$EXCLUDED_SKILLS$2 "; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

for name in "${SKILLS[@]}" $EXCLUDED_SKILLS; do
  skill_dir "$name" > /dev/null || { echo "no such skill: $name" >&2; exit 1; }
done

mkdir -p "$TARGET/.agents/skills" "$TARGET/.agents/rules" "$TARGET/.claude" "$TARGET/.codex/hooks"
TARGET="$(cd "$TARGET" && pwd)"
MANIFEST="$TARGET/.agents/scaffold-manifest"

was_added() {
  [ -f "$MANIFEST" ] && grep -qxF -- "$1" "$MANIFEST"
}

record_added() {
  was_added "$1" || echo "$1" >> "$MANIFEST"
}

copy_if_missing() {
  if [ -e "$2" ] || [ -L "$2" ]; then echo "kept     ${2#"$TARGET"/}"; else cp "$1" "$2"; echo "added    ${2#"$TARGET"/}"; fi
}

link_if_missing() {
  if [ -e "$2" ] || [ -L "$2" ]; then echo "kept     ${2#"$TARGET"/}"; else ln -s "$1" "$2"; echo "added    ${2#"$TARGET"/} -> $1"; fi
}

git -C "$TARGET" rev-parse --is-inside-work-tree > /dev/null 2>&1 || { git -C "$TARGET" init -q -b main; echo "added    git repository (main)"; }

copy_if_missing "$TEMPLATE/AGENTS.md" "$TARGET/AGENTS.md"
link_if_missing AGENTS.md "$TARGET/CLAUDE.md"
link_if_missing ../.agents/skills "$TARGET/.claude/skills"
link_if_missing ../.agents/rules "$TARGET/.claude/rules"
copy_if_missing "$TEMPLATE/codex/hooks.json" "$TARGET/.codex/hooks.json"
copy_if_missing "$TEMPLATE/codex/hooks/load_agent_rules.js" "$TARGET/.codex/hooks/load_agent_rules.js"

RULES="commits coding-style no-ai-mentions how-we-work pr-descriptions agent-feedback"
[ "$TYPESCRIPT" = 0 ] || RULES="$RULES symnav"
for rule in $RULES; do
  destination="$TARGET/.agents/rules/$rule.md"
  if [ ! -e "$destination" ] && was_added "rule:$rule"; then echo "skipped  rule $rule (removed earlier)"; continue; fi
  copy_if_missing "$TEMPLATE/rules/$rule.md" "$destination"
  record_added "rule:$rule"
done

touch "$TARGET/.gitignore"
added_ignores=0
while IFS= read -r line; do
  grep -qxF -- "$line" "$TARGET/.gitignore" || { echo "$line" >> "$TARGET/.gitignore"; added_ignores=$((added_ignores + 1)); }
done < "$TEMPLATE/gitignore"
echo "added    $added_ignores .gitignore lines"

for name in "${SKILLS[@]}"; do
  destination="$TARGET/.agents/skills/$name"
  if is_listed "$EXCLUDED_SKILLS" "$name" && [ ! -e "$destination" ]; then echo "skipped  skill $name (--no-skill)"; record_added "skill:$name"; continue; fi
  if [ -e "$destination" ]; then echo "kept     skill $name"; record_added "skill:$name"; continue; fi
  if was_added "skill:$name" && ! is_listed "$EXPLICIT_SKILLS" "$name"; then echo "skipped  skill $name (removed earlier)"; continue; fi
  rsync -aL --exclude runs/ --exclude tmp/ --exclude evals/ --exclude node_modules/ --exclude .DS_Store \
    "$(skill_dir "$name")/" "$destination/"
  echo "added    skill $name"
  record_added "skill:$name"
done
