#!/usr/bin/env bash
# sdd-new.sh — create a spec folder without a conversation.
# Writes specs/active/YYYY-MM-DD-<name>/ with the spec frontmatter and the
# requirements.md clarifications ledger, then prints the folder name.
# Branch creation stays with the caller.
#
# Usage: sdd-new.sh <name> --work-type <t> --rigor <r>
#                   [--title <title>] [--branch <b>] [--goal <text>]
#   --goal seeds `## Goal`; docs and chore have no specify phase to write it.
# Exit codes: 0 created · 2 usage or folder exists · 3 unknown type/rigor
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ACTIVE="$ROOT/specs/active"

usage() {
  echo "usage: sdd-new.sh <name> --work-type <t> --rigor <r> [--title <title>] [--branch <b>] [--goal <text>]" >&2
  exit 2
}

name=""; wtype=""; rigor=""; title=""; branch=""; goal=""
while [ $# -gt 0 ]; do
  case "$1" in
    --work-type|--rigor|--title|--branch|--goal)
      [ $# -ge 2 ] || usage
      case "$1" in
        --work-type) wtype="$2" ;;
        --rigor) rigor="$2" ;;
        --title) title="$2" ;;
        --branch) branch="$2" ;;
        --goal) goal="$2" ;;
      esac
      shift 2 ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *) [ -z "$name" ] || usage; name="$1"; shift ;;
  esac
done
[ -n "$name" ] && [ -n "$wtype" ] && [ -n "$rigor" ] || usage
printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
  || { echo "name must be kebab-case: $name" >&2; exit 2; }

case "$wtype" in
  feature|decision|fix|docs|chore) ;;
  *) echo "unknown work-type: $wtype" >&2; exit 3 ;;
esac
case "$rigor" in
  low|medium|high|xhigh|max) ;;
  *) echo "unknown rigor: $rigor" >&2; exit 3 ;;
esac

today="$(date +%Y-%m-%d)"
folder="$today-$name"
DIR="$ACTIVE/$folder"
[ -e "$DIR" ] && { echo "spec folder exists: specs/active/$folder" >&2; exit 2; }

case "$wtype" in
  feature) [ "$rigor" = low ] && template=spec-mini || template=spec ;;
  decision) template=decision ;;
  fix) template=fix ;;
  *) template="" ;;
esac
case "$wtype" in
  fix) prefix=bugfix ;;
  chore) prefix=chore ;;
  *) prefix=feature ;;
esac
branch="${branch:-$prefix/$folder}"
if [ -z "$title" ]; then
  title="$(printf '%s' "$name" | tr '-' ' ')"
  title="$(printf '%s' "${title:0:1}" | tr '[:lower:]' '[:upper:]')${title:1}"
fi

mkdir -p "$DIR"
{
  echo '---'
  echo "id: $folder"
  echo "title: $title"
  echo "status: active"
  echo "work-type: $wtype"
  echo "rigor: $rigor"
  echo "branch: $branch"
  echo "created: $today"
  echo '---'
  if [ -n "$goal" ]; then
    printf '\n# %s\n\n## Goal\n\n%s\n' "$title" "$goal"
  fi
  if [ -n "$template" ]; then
    printf '\n<!-- specify writes the body from .prospect/templates/%s.template.md -->\n' "$template"
  fi
} > "$DIR/spec.md"

cat > "$DIR/requirements.md" <<EOF
# Requirements: $title

## Clarifications

<!-- - [status] Q: … → A: …   status: resolved | open | assumed -->
EOF

echo "$folder"
exit 0
