#!/usr/bin/env bash
# Bake .prospect-manifest.json into a staged release artifact.
#
# Usage: bash scripts/build-manifest.sh <stage_dir> <version>
#
# The manifest records the SHA-256 of every installable file as shipped. The
# installer copies those checksums into the target repository as the tracked
# baseline, so it never has to derive one by hashing a file in the target —
# which, for a file the user has edited, would record the edit as pristine.
#
# File categories come from install.sh so classification has a single home.

set -euo pipefail

STAGE="${1:?stage_dir required}"
VERSION="${2:?version required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
_PROSPECT_SOURCED=1 source "$SCRIPT_DIR/../install.sh"

entries=()
while IFS= read -r -d '' file; do
  rel="${file#"$STAGE"/}"
  [[ "$(basename "$rel")" == ".gitkeep" ]] && continue

  case "$(classify_file "$rel")" in
    excluded | user-content) continue ;;
  esac

  entries+=("\"$rel\":\"$(_compute_sha256 "$file")\"")
done < <(find "$STAGE" -type f -print0 | sort -z)

printf '{"version":"%s","files":{%s}}\n' \
  "$VERSION" "$(IFS=,; printf '%s' "${entries[*]:-}")" \
  > "$STAGE/.prospect-manifest.json"
