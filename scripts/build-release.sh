#!/usr/bin/env bash
# Build a release artifact for Prospect.
#
# Usage: bash scripts/build-release.sh <version>
# Example: bash scripts/build-release.sh v1.0.0
#
# Produces:
#   prospect-<version>.tar.gz
#   prospect-<version>.zip
#
# The archives are written to the current working directory.
# Paths of created archives are printed to stdout.

set -euo pipefail

# ── Argument validation ───────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>  (e.g. v1.0.0)" >&2
  exit 1
fi

VERSION="$1"
ARCHIVE_NAME="prospect-${VERSION}"

# ── Locate repo root ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Temp directory (cleaned up on exit) ──────────────────────────────────────

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

STAGE="$WORK_DIR/$ARCHIVE_NAME"

# ── Stage distributable files ────────────────────────────────────────────────

mkdir -p "$STAGE"

# .claude/ — all agents, skills, and workflows
if [[ -d "$REPO_ROOT/.claude" ]]; then
  cp -r "$REPO_ROOT/.claude" "$STAGE/.claude"
fi

# .prospect/ — framework runtime: resolver, prompts, templates, policy
if [[ -d "$REPO_ROOT/.prospect" ]]; then
  cp -r "$REPO_ROOT/.prospect" "$STAGE/.prospect"
fi

# standards/global/
if [[ -d "$REPO_ROOT/standards/global" ]]; then
  mkdir -p "$STAGE/standards"
  cp -r "$REPO_ROOT/standards/global" "$STAGE/standards/global"
fi

# specs/REGISTRY.md — seeded on install when absent, never overwritten
if [[ -f "$REPO_ROOT/specs/REGISTRY.md" ]]; then
  mkdir -p "$STAGE/specs"
  cp "$REPO_ROOT/specs/REGISTRY.md" "$STAGE/specs/REGISTRY.md"
fi

# specs/active/ and specs/archive/ — directory markers only (no content)
mkdir -p "$STAGE/specs/active"
touch "$STAGE/specs/active/.gitkeep"

mkdir -p "$STAGE/specs/archive"
touch "$STAGE/specs/archive/.gitkeep"

# product/ — template files only; never include mission.md or roadmap.md
if [[ -d "$REPO_ROOT/product" ]]; then
  mkdir -p "$STAGE/product"
  for f in "$REPO_ROOT/product/"*.template.md; do
    [[ -f "$f" ]] && cp "$f" "$STAGE/product/"
  done
fi

# Root files
for f in CLAUDE.md README.md install.sh install.ps1; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    cp "$REPO_ROOT/$f" "$STAGE/$f"
  fi
done

# ── Bake the manifest ─────────────────────────────────────────────────────────
# Checksums are taken here, from the files as shipped, so the installer never
# derives a baseline from a file in the target repository.

bash "$SCRIPT_DIR/build-manifest.sh" "$STAGE" "$VERSION"

# ── Produce archives ──────────────────────────────────────────────────────────

OUT_DIR="$(pwd)"
TARBALL="$OUT_DIR/${ARCHIVE_NAME}.tar.gz"
ZIPFILE="$OUT_DIR/${ARCHIVE_NAME}.zip"

# tar.gz — created from within the work directory so the archive root is
# prospect-<version>/ (not an absolute path).
tar -czf "$TARBALL" -C "$WORK_DIR" "$ARCHIVE_NAME"

# zip — same relative-root approach
if command -v zip &>/dev/null; then
  (cd "$WORK_DIR" && zip -r "$ZIPFILE" "$ARCHIVE_NAME" -x "*.DS_Store")
else
  # Fallback: PowerShell on Windows (Git Bash environment)
  powershell.exe -NoProfile -Command \
    "Compress-Archive -Path '$WORK_DIR/$ARCHIVE_NAME' -DestinationPath '$ZIPFILE'" \
    2>/dev/null || {
      echo "WARNING: zip not available; skipping .zip artifact" >&2
    }
fi

# ── Report ────────────────────────────────────────────────────────────────────

echo "$TARBALL"
# Only report the zip path if it was successfully produced.
# Use `true` to ensure the script exits 0 when zip is unavailable.
[[ -f "$ZIPFILE" ]] && echo "$ZIPFILE" || true
