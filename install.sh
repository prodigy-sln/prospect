#!/usr/bin/env bash
# install.sh — Prospect install/update script
# Implements: FR-1.4 (version argument), FR-2.5 (toolchain flags)

set -euo pipefail

# ── Version resolution ─────────────────────────────────────────────────────────

# _fetch_latest_version_tag
# Queries the GitHub API for the latest Prospect release tag.
# Tests override this function to avoid network calls.
_fetch_latest_version_tag() {
  curl -fsSL "https://api.github.com/repos/prodigy-sln/prospect/releases/latest" \
    | grep '"tag_name"' \
    | head -1 \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
}

# resolve_version [version]
# No arg or "latest" → fetch latest tag via _fetch_latest_version_tag.
# Valid semver vX.Y.Z → echo unchanged.
# Anything else → exit non-zero with an error message.
resolve_version() {
  local requested="${1:-latest}"

  if [[ "$requested" == "latest" ]]; then
    local tag
    if ! tag="$(_fetch_latest_version_tag)"; then
      echo "Error: failed to fetch latest version from GitHub API" >&2
      return 1
    fi
    echo "$tag"
    return 0
  fi

  if [[ "$requested" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$requested"
    return 0
  fi

  echo "Error: invalid version format '$requested'. Expected vX.Y.Z (e.g. v1.2.3) or 'latest'." >&2
  return 1
}

# ── Argument parsing ───────────────────────────────────────────────────────────

usage() {
  cat <<EOF
usage: install.sh [OPTIONS] [VERSION]

Install or update the Prospect SDD framework in the current directory.

OPTIONS:
  --claude      Install Claude Code toolchain only
  --copilot     Install VS Code Copilot toolchain only
  --all         Install both toolchains (default)
  --help        Print this help message and exit

VERSION:
  Optional semver tag, e.g. v1.2.3. Defaults to the latest release.

EXAMPLES:
  install.sh
  install.sh v1.2.0
  install.sh --claude
  install.sh v1.2.0 --claude
EOF
}

parse_args() {
  TOOLCHAIN=""
  VERSION_ARG="latest"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        usage
        exit 0
        ;;
      --claude)
        TOOLCHAIN="claude"
        shift
        ;;
      --copilot)
        TOOLCHAIN="copilot"
        shift
        ;;
      --all)
        TOOLCHAIN="all"
        shift
        ;;
      v[0-9]*.[0-9]*.[0-9]*)
        VERSION_ARG="$1"
        shift
        ;;
      *)
        echo "Error: unknown option '$1'" >&2
        echo "Run 'install.sh --help' for usage." >&2
        exit 1
        ;;
    esac
  done

  export TOOLCHAIN VERSION_ARG
}

# ── Download ───────────────────────────────────────────────────────────────────

# GitHub repository used to construct release download URLs.
# Override in tests or environment to point at a mirror/fork.
PROSPECT_REPO_URL="${PROSPECT_REPO_URL:-https://github.com/prodigy-sln/prospect}"

# _download_artifact <url> <dest_file>
# Downloads <url> to <dest_file> using curl.
# Returns non-zero and prints an error on failure.
_download_artifact() {
  local url="$1"
  local dest_file="$2"
  curl -fsSL -o "$dest_file" "$url"
}

# download_release <version> <dest_dir>
# Downloads the release tarball for <version>, extracts its contents into
# <dest_dir>, and removes the temporary tarball.
# The tarball is expected to contain a single top-level directory
# prospect-<version>/ whose contents are moved to <dest_dir>.
download_release() {
  local version="$1"
  local dest_dir="$2"

  local url="${PROSPECT_REPO_URL}/releases/download/${version}/prospect-${version}.tar.gz"
  local tmp_tarball
  tmp_tarball="$(mktemp --suffix=".tar.gz")"

  # Ensure the temp file is removed on any exit from this function.
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_tarball'" RETURN

  if ! _download_artifact "$url" "$tmp_tarball"; then
    echo "Error: failed to download release $version from $url" >&2
    return 1
  fi

  local tmp_extract
  tmp_extract="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_tarball'; rm -rf '$tmp_extract'" RETURN

  if ! tar -xzf "$tmp_tarball" -C "$tmp_extract"; then
    echo "Error: downloaded file is not a valid archive for version $version" >&2
    return 1
  fi

  # Move extracted contents (from prospect-<version>/ subdirectory) into dest_dir.
  local extracted_root="$tmp_extract/prospect-${version}"
  if [[ -d "$extracted_root" ]]; then
    # Copy all contents (including hidden files) from extracted root to dest_dir.
    cp -a "$extracted_root/." "$dest_dir/"
  else
    # Fallback: copy everything extracted directly.
    cp -a "$tmp_extract/." "$dest_dir/"
  fi

  rm -rf "$tmp_extract"
}

# ── Toolchain selection ────────────────────────────────────────────────────────

# select_toolchain <target_dir>
# Resolves the toolchain to install.  Priority order:
#   1. TOOLCHAIN env var set by --claude / --copilot / --all flag → use as-is
#   2. .prospect-manifest.json in <target_dir> exists → derive from toolchains array
#   3. Interactive stdin → prompt user (not exercised in tests)
#   4. Non-interactive (default) → "all"
#
# Echoes one of: claude | copilot | all
select_toolchain() {
  local target_dir="${1:-$PWD}"

  # 1. CLI flag wins unconditionally.
  if [[ -n "${TOOLCHAIN:-}" ]]; then
    echo "$TOOLCHAIN"
    return 0
  fi

  # 2. Manifest-based default.
  local manifest="$target_dir/.prospect-manifest.json"
  if [[ -f "$manifest" ]]; then
    # Extract the toolchains array value using grep/sed — no jq needed.
    # Input looks like: "toolchains":["claude","copilot"]
    local raw_array
    raw_array="$(grep -o '"toolchains":\[[^]]*\]' "$manifest" | sed 's/"toolchains"://')"

    local has_claude=0 has_copilot=0
    [[ "$raw_array" == *'"claude"'* ]] && has_claude=1
    [[ "$raw_array" == *'"copilot"'* ]] && has_copilot=1

    if [[ $has_claude -eq 1 && $has_copilot -eq 1 ]]; then
      echo "all"
    elif [[ $has_claude -eq 1 ]]; then
      echo "claude"
    elif [[ $has_copilot -eq 1 ]]; then
      echo "copilot"
    else
      echo "all"
    fi
    return 0
  fi

  # 3. Interactive prompt (stdin is a terminal).
  if [[ -t 0 ]]; then
    echo "Select toolchain to install:" >&2
    echo "  1) claude" >&2
    echo "  2) copilot" >&2
    echo "  3) all (default)" >&2
    local choice
    read -r -p "Choice [3]: " choice </dev/tty
    case "$choice" in
      1) echo "claude" ;;
      2) echo "copilot" ;;
      *) echo "all" ;;
    esac
    return 0
  fi

  # 4. Non-interactive default.
  echo "all"
}

# ── File categorization ────────────────────────────────────────────────────────

# classify_file <relative_path>
# Echoes the category of the file: "framework", "customizable", "user-content",
# or "template". Used by the installer to decide how to handle each file on
# install and update (FR-5.1 – FR-5.4).
classify_file() {
  local path="$1"

  case "$path" in
    product/mission.template.md|product/roadmap.template.md)
      echo "template"
      ;;
    .claude/agents/*|.claude/skills/*|\
    .github/agents/*|.github/prompts/*|.github/instructions/*|\
    specs/_templates/*)
      echo "framework"
      ;;
    standards/global/*.md|CLAUDE.md|.github/copilot-instructions.md)
      echo "customizable"
      ;;
    specs/active/*|specs/implemented/*|product/mission.md|product/roadmap.md)
      echo "user-content"
      ;;
    *)
      echo "framework"
      ;;
  esac
}

# ── SHA-256 checksum ───────────────────────────────────────────────────────────

# _compute_sha256 <file>
# Computes the SHA-256 checksum of a file, cross-platform.
_compute_sha256() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    powershell.exe -NoProfile -Command \
      "(Get-FileHash -Algorithm SHA256 '$file').Hash.ToLower()" 2>/dev/null || {
      echo "ERROR: no sha256 tool found" >&2
      return 1
    }
  fi
}

# ── Manifest read/write ────────────────────────────────────────────────────────

# write_manifest <target_dir> <version> <toolchains> <file1> [file2] ...
# Writes .prospect-manifest.json to target_dir.
# toolchains is a space- or comma-separated string, e.g. "claude copilot".
# Each file argument is a relative path; the function computes its sha256
# from the actual file at target_dir/relative_path (FR-4.2).
write_manifest() {
  local target_dir="$1"
  local version="$2"
  local toolchains_raw="$3"
  shift 3
  local files=("$@")

  # Build toolchains JSON array from space- or comma-separated input.
  local tc_json=""
  local first=1
  # Normalise separators: replace commas with spaces, then split on whitespace.
  local tc_list
  tc_list="$(printf '%s' "$toolchains_raw" | tr ',' ' ')"
  for tc in $tc_list; do
    if [[ $first -eq 1 ]]; then
      tc_json="\"$tc\""
      first=0
    else
      tc_json="$tc_json,\"$tc\""
    fi
  done

  # Build files JSON object.
  local files_json=""
  local first_file=1
  for rel_path in "${files[@]}"; do
    local checksum
    checksum="$(_compute_sha256 "$target_dir/$rel_path")"
    if [[ $first_file -eq 1 ]]; then
      files_json="\"$rel_path\":\"$checksum\""
      first_file=0
    else
      files_json="$files_json,\"$rel_path\":\"$checksum\""
    fi
  done

  printf '{"version":"%s","toolchains":[%s],"files":{%s}}\n' \
    "$version" "$tc_json" "$files_json" \
    > "$target_dir/.prospect-manifest.json"
}

# read_manifest_version <target_dir>
# Reads the version string from .prospect-manifest.json (FR-4.3).
read_manifest_version() {
  local target_dir="$1"
  local manifest="$target_dir/.prospect-manifest.json"

  [[ -f "$manifest" ]] || { echo ""; return 1; }

  # Extract "version":"<value>" from single-line JSON.
  grep -o '"version":"[^"]*"' "$manifest" \
    | sed 's/"version":"//;s/"//'
}

# read_manifest_toolchains <target_dir>
# Reads the toolchains array from .prospect-manifest.json and echoes the
# entries as a space-separated string (FR-4.3).
read_manifest_toolchains() {
  local target_dir="$1"
  local manifest="$target_dir/.prospect-manifest.json"

  [[ -f "$manifest" ]] || { echo ""; return 1; }

  # Extract the toolchains array content, e.g. ["claude","copilot"]
  # -> claude copilot
  grep -o '"toolchains":\[[^]]*\]' "$manifest" \
    | sed 's/"toolchains":\[//;s/\]//' \
    | tr -d '"' \
    | tr ',' ' '
}

# read_manifest_checksum <target_dir> <relative_path>
# Reads the stored sha256 checksum for relative_path from the manifest.
# Returns empty string (and exit 0) when the path is not in the manifest.
# (FR-3.1 / FR-4.2)
read_manifest_checksum() {
  local target_dir="$1"
  local rel_path="$2"
  local manifest="$target_dir/.prospect-manifest.json"

  [[ -f "$manifest" ]] || { echo ""; return 0; }

  # Escape characters that are special in basic regex: . / * [ ]
  local escaped
  escaped="$(printf '%s' "$rel_path" | sed 's/[.[\/*^$]/\\&/g')"

  grep -o "\"$escaped\":\"[^\"]*\"" "$manifest" \
    | sed "s/\"$escaped\":\"//;s/\"$//" \
    || true
}

# ── Version file ───────────────────────────────────────────────────────────────

# write_version_file <target_dir> <version>
# Writes .prospect-version containing exactly the version string (FR-4.1).
write_version_file() {
  local target_dir="$1"
  local version="$2"
  printf '%s\n' "$version" > "$target_dir/.prospect-version"
}

# ── Install orchestration ──────────────────────────────────────────────────────

# install_files <source_dir> <target_dir> <version> <toolchain>
# Orchestrates the full install/update flow.
# Copies files from source_dir into target_dir, applying toolchain filter,
# conflict detection, and manifest/version tracking.
install_files() {
  local source_dir="$1"
  local target_dir="$2"
  local version="$3"
  local toolchain="$4"

  # FR-7.1: Warn if target_dir is not a git repo, but continue.
  if [[ ! -d "$target_dir/.git" ]]; then
    echo "Warning: $target_dir is not a git repository. It is recommended to run Prospect inside a git repo." >&2
  fi

  # Check if manifest exists (determines fresh install vs update).
  local manifest_exists=0
  [[ -f "$target_dir/.prospect-manifest.json" ]] && manifest_exists=1

  # FR-7.3: Idempotency — if same version and all files match, skip.
  if [[ $manifest_exists -eq 1 ]]; then
    local current_version
    current_version="$(read_manifest_version "$target_dir")"
    if [[ "$current_version" == "$version" ]]; then
      # Check if any files would change.
      local any_diff=0
      while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#$source_dir/}"
        local category
        category="$(classify_file "$rel_path")"
        [[ "$category" == "user-content" ]] && continue

        # Apply toolchain filter.
        if [[ "$toolchain" == "claude" ]]; then
          [[ "$rel_path" == .github/* ]] && continue
        elif [[ "$toolchain" == "copilot" ]]; then
          [[ "$rel_path" == .claude/* ]] && continue
          [[ "$rel_path" == "CLAUDE.md" ]] && continue
        fi

        local target_file="$target_dir/$rel_path"
        [[ ! -f "$target_file" ]] && { any_diff=1; break; }

        local src_sum target_sum manifest_sum
        src_sum="$(_compute_sha256 "$src_file")"
        target_sum="$(_compute_sha256 "$target_file")"
        manifest_sum="$(read_manifest_checksum "$target_dir" "$rel_path")"
        if [[ "$src_sum" != "$target_sum" ]]; then
          any_diff=1
          break
        fi
      done < <(find "$source_dir" -type f -print0)

      if [[ $any_diff -eq 0 ]]; then
        echo "Already up to date (${version})."
        return 0
      fi
    fi
  fi

  # Track installed files and outcomes.
  local -a installed_files=()
  local -a skipped_files=()
  local -a conflict_files=()

  # FR-5.4: Ensure required directories exist.
  mkdir -p "$target_dir/specs/active"
  mkdir -p "$target_dir/specs/implemented"
  mkdir -p "$target_dir/product"

  # Walk source_dir for all files.
  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$source_dir/}"

    # Skip .gitkeep files (used only to preserve empty dirs in artifacts).
    [[ "$(basename "$rel_path")" == ".gitkeep" ]] && continue

    # Apply toolchain filter (FR-2.2, FR-2.3).
    if [[ "$toolchain" == "claude" ]]; then
      [[ "$rel_path" == .github/* ]] && continue
    elif [[ "$toolchain" == "copilot" ]]; then
      [[ "$rel_path" == .claude/* ]] && continue
      [[ "$rel_path" == "CLAUDE.md" ]] && continue
    fi

    local category
    category="$(classify_file "$rel_path")"

    local target_file="$target_dir/$rel_path"

    # FR-5.3: user-content — never touch if file already exists.
    if [[ "$category" == "user-content" ]]; then
      if [[ -f "$target_file" ]]; then
        skipped_files+=("$rel_path")
        continue
      fi
      # User-content files in the artifact are templates/placeholders; skip them.
      continue
    fi

    # FR-3.5: Special case for .github/copilot-instructions.md.
    # If pre-exists with no manifest entry, treat as non-Prospect content.
    if [[ "$rel_path" == ".github/copilot-instructions.md" && -f "$target_file" && $manifest_exists -eq 0 ]]; then
      local manifest_sum
      manifest_sum="$(read_manifest_checksum "$target_dir" "$rel_path")"
      if [[ -z "$manifest_sum" ]]; then
        echo "Note: .github/copilot-instructions.md already exists with existing content. Please merge manually with the Prospect version." >&2
        skipped_files+=("$rel_path")
        continue
      fi
    fi

    # Ensure parent directory exists.
    mkdir -p "$(dirname "$target_file")"

    if [[ $manifest_exists -eq 0 ]]; then
      # Fresh install: copy everything (FR-3.1).
      cp "$src_file" "$target_file"
      installed_files+=("$rel_path")
    else
      # Update: checksum-based conflict detection (FR-3.2, FR-3.3).
      local manifest_sum
      manifest_sum="$(read_manifest_checksum "$target_dir" "$rel_path")"

      if [[ ! -f "$target_file" ]]; then
        # New file in this version — just copy it.
        cp "$src_file" "$target_file"
        installed_files+=("$rel_path")
      elif [[ -z "$manifest_sum" ]]; then
        # File not previously tracked (new in this version) — copy it.
        cp "$src_file" "$target_file"
        installed_files+=("$rel_path")
      else
        local current_sum
        current_sum="$(_compute_sha256 "$target_file")"

        if [[ "$current_sum" == "$manifest_sum" ]]; then
          # FR-3.2: Unmodified — overwrite silently with new version.
          cp "$src_file" "$target_file"
          installed_files+=("$rel_path")
        else
          # FR-3.3: User-modified — write as .prospect-incoming.
          cp "$src_file" "${target_file}.prospect-incoming"
          conflict_files+=("$rel_path")
        fi
      fi
    fi
  done < <(find "$source_dir" -type f -print0)

  # Write manifest and version file (FR-4.1, FR-4.2).
  # Collect all files currently installed (existing + newly installed).
  local -a manifest_files=()
  for f in "${installed_files[@]}"; do
    manifest_files+=("$f")
  done
  # Also include previously-tracked files that weren't touched (conflicts or unchanged).
  if [[ $manifest_exists -eq 1 ]]; then
    for f in "${conflict_files[@]}"; do
      manifest_files+=("$f")
    done
    # Re-add any files already in manifest that we didn't touch.
    # (They remain installed from prior run.)
    local prev_files
    if prev_files="$(grep -o '"[^"]*":"[^"]*"' "$target_dir/.prospect-manifest.json" \
        | grep -v '"version"' | grep -v '"toolchains"' | sed 's/:"[^"]*"//' | tr -d '"' 2>/dev/null)"; then
      while IFS= read -r prev_file; do
        [[ -z "$prev_file" ]] && continue
        # Skip if already in our list.
        local already=0
        for m in "${manifest_files[@]:-}"; do
          [[ "$m" == "$prev_file" ]] && { already=1; break; }
        done
        if [[ $already -eq 0 && -f "$target_dir/$prev_file" ]]; then
          manifest_files+=("$prev_file")
        fi
      done <<< "$prev_files"
    fi
  fi

  if [[ ${#manifest_files[@]} -gt 0 ]]; then
    write_manifest "$target_dir" "$version" "$toolchain" "${manifest_files[@]}"
  else
    write_manifest "$target_dir" "$version" "$toolchain"
  fi
  write_version_file "$target_dir" "$version"

  # FR-3.4: Print summary.
  echo "Prospect ${version} installed (toolchain: ${toolchain})."
  if [[ ${#installed_files[@]} -gt 0 ]]; then
    echo "  Installed: ${#installed_files[@]} file(s)."
  fi
  if [[ ${#skipped_files[@]} -gt 0 ]]; then
    echo "  Skipped (user content): ${#skipped_files[@]} file(s)."
  fi
  if [[ ${#conflict_files[@]} -gt 0 ]]; then
    echo "  Conflicts detected — ${#conflict_files[@]} file(s) saved as .prospect-incoming:"
    for f in "${conflict_files[@]}"; do
      echo "    $target_dir/${f}.prospect-incoming"
    done
    echo "  Review and merge the .prospect-incoming files to complete the update."
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"

  # Allow tests to verify parsing without triggering network/install.
  if [[ "${PROSPECT_DRY_RUN:-}" == "1" ]]; then
    echo "TOOLCHAIN=${TOOLCHAIN:-} VERSION_ARG=${VERSION_ARG:-}"
    return 0
  fi

  local version
  version="$(resolve_version "$VERSION_ARG")"

  local toolchain
  toolchain="$(select_toolchain "$PWD")"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" EXIT

  download_release "$version" "$tmp_dir"

  local source_dir="$tmp_dir/prospect-${version}"
  if [[ ! -d "$source_dir" ]]; then
    source_dir="$tmp_dir"
  fi

  install_files "$source_dir" "$PWD" "$version" "$toolchain"
}

if [[ "${_PROSPECT_SOURCED:-}" != "1" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
