#!/usr/bin/env bash
# install.sh — Prospect install/update script
# Implements: FR-1.4 (version argument)

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
  --help        Print this help message and exit

VERSION:
  Optional semver tag, e.g. v1.2.3. Defaults to the latest release.

EXAMPLES:
  install.sh
  install.sh v1.2.0
EOF
}

parse_args() {
  VERSION_ARG="latest"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        usage
        exit 0
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

  export VERSION_ARG
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

# ── File categorization ────────────────────────────────────────────────────────

# classify_file <relative_path>
# Echoes the category of the file: "framework", "customizable", "user-content",
# "template", "install-once", or "excluded". Used by the installer to decide how
# to handle each file on install and update.
#   framework/customizable/template — written on install, conflict-checked on update
#   user-content                    — never touched when it already exists
#   install-once                    — seeded when absent, never overwritten (REGISTRY)
#   excluded                        — ships in the artifact, never enters a project
classify_file() {
  local path="$1"

  case "$path" in
    install.sh|install.ps1|README.md|.prospect-manifest.json|.prospect-version)
      # Installer plumbing and the framework's own README. They belong to the
      # release artifact, not to the target repository — copying README.md
      # would overwrite the project's own.
      echo "excluded"
      ;;
    specs/REGISTRY.md)
      echo "install-once"
      ;;
    product/mission.template.md|product/roadmap.template.md)
      echo "template"
      ;;
    .claude/agents/*|.claude/skills/*|.claude/workflows/*|.prospect/*)
      echo "framework"
      ;;
    standards/global/*.md|CLAUDE.md)
      echo "customizable"
      ;;
    specs/active/*|specs/archive/*|docs/*|product/mission.md|product/roadmap.md)
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

# write_manifest <target_dir> <version> [<rel_path> <sha256>]...
# Writes .prospect-manifest.json to target_dir (FR-4.2).
#
# Checksums are supplied by the caller and are always the checksum of the
# content Prospect shipped. The function deliberately cannot hash files in
# target_dir: on a conflicted update the file there holds the user's edits,
# and recording those as the baseline would make the next update mistake the
# file for pristine and overwrite it.
write_manifest() {
  local target_dir="$1"
  local version="$2"
  shift 2

  local files_json=""
  while [[ $# -gt 1 ]]; do
    [[ -n "$files_json" ]] && files_json="${files_json},"
    files_json="${files_json}\"$1\":\"$2\""
    shift 2
  done

  printf '{"version":"%s","files":{%s}}\n' \
    "$version" "$files_json" \
    > "$target_dir/.prospect-manifest.json"
}

# _manifest_lookup <manifest_file> <relative_path>
# Echoes the stored sha256 for relative_path, or nothing when absent.
_manifest_lookup() {
  local manifest="$1"
  local rel_path="$2"

  [[ -f "$manifest" ]] || return 0

  # Escape characters that are special in basic regex.
  local escaped
  escaped="$(printf '%s' "$rel_path" | sed 's/[.[\/*^$]/\\&/g')"

  grep -o "\"$escaped\":\"[^\"]*\"" "$manifest" \
    | sed "s/\"$escaped\":\"//;s/\"$//" \
    || true
}

# shipped_checksum <source_dir> <relative_path>
# Echoes the sha256 of the file as shipped, read from the artifact's baked
# manifest. Falls back to hashing the artifact file for releases built before
# the manifest was baked at build time.
shipped_checksum() {
  local source_dir="$1"
  local rel_path="$2"

  local checksum
  checksum="$(_manifest_lookup "$source_dir/.prospect-manifest.json" "$rel_path")"
  [[ -n "$checksum" ]] || checksum="$(_compute_sha256 "$source_dir/$rel_path")"

  printf '%s' "$checksum"
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

# read_manifest_checksum <target_dir> <relative_path>
# Reads the stored sha256 checksum for relative_path from the manifest.
# Returns empty string (and exit 0) when the path is not in the manifest.
# (FR-3.1 / FR-4.2)
read_manifest_checksum() {
  local target_dir="$1"
  local rel_path="$2"

  _manifest_lookup "$target_dir/.prospect-manifest.json" "$rel_path"
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

# install_files <source_dir> <target_dir> <version>
# Orchestrates the full install/update flow.
# Copies files from source_dir into target_dir, applying conflict detection
# and manifest/version tracking.
install_files() {
  local source_dir="$1"
  local target_dir="$2"
  local version="$3"

  # An empty source would otherwise report a successful install of nothing.
  if [[ -z "$(find "$source_dir" -type f 2>/dev/null | head -1)" ]]; then
    echo "Error: no files found in $source_dir — the release artifact is empty or was not extracted." >&2
    return 1
  fi

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
        [[ "$(basename "$rel_path")" == ".gitkeep" ]] && continue
        local category
        category="$(classify_file "$rel_path")"
        [[ "$category" == "user-content" ]] && continue
        [[ "$category" == "install-once" ]] && continue
        [[ "$category" == "excluded" ]] && continue

        local target_file="$target_dir/$rel_path"
        [[ ! -f "$target_file" ]] && { any_diff=1; break; }

        local target_sum
        target_sum="$(_compute_sha256 "$target_file")"
        if [[ "$(shipped_checksum "$source_dir" "$rel_path")" != "$target_sum" ]]; then
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
  # Flat rel_path/checksum pairs for the new manifest.
  local -a manifest_pairs=()

  # FR-5.4: Ensure required directories exist.
  mkdir -p "$target_dir/specs/active"
  mkdir -p "$target_dir/specs/archive"
  mkdir -p "$target_dir/product"

  # Walk source_dir for all files.
  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$source_dir/}"

    # Skip .gitkeep files (used only to preserve empty dirs in artifacts).
    [[ "$(basename "$rel_path")" == ".gitkeep" ]] && continue

    local category
    category="$(classify_file "$rel_path")"

    local target_file="$target_dir/$rel_path"

    # Installer plumbing never enters the target repository.
    if [[ "$category" == "excluded" ]]; then
      continue
    fi

    # FR-5.3: user-content — never touch if file already exists.
    if [[ "$category" == "user-content" ]]; then
      if [[ -f "$target_file" ]]; then
        skipped_files+=("$rel_path")
        continue
      fi
      # User-content files in the artifact are templates/placeholders; skip them.
      continue
    fi

    # install-once — seed the registry when absent, never overwrite it.
    if [[ "$category" == "install-once" ]]; then
      if [[ -f "$target_file" ]]; then
        skipped_files+=("$rel_path")
        continue
      fi
      mkdir -p "$(dirname "$target_file")"
      cp "$src_file" "$target_file"
      installed_files+=("$rel_path")
      manifest_pairs+=("$rel_path" "$(shipped_checksum "$source_dir" "$rel_path")")
      continue
    fi

    # Ensure parent directory exists.
    mkdir -p "$(dirname "$target_file")"

    # The checksum of this file as shipped becomes the tracked baseline
    # whatever the outcome below — it describes what Prospect offered, never
    # what the target repository happens to hold.
    local shipped_sum
    shipped_sum="$(shipped_checksum "$source_dir" "$rel_path")"
    manifest_pairs+=("$rel_path" "$shipped_sum")

    if [[ ! -f "$target_file" ]]; then
      # FR-3.1: not present yet — copy it.
      cp "$src_file" "$target_file"
      installed_files+=("$rel_path")
      continue
    fi

    local current_sum baseline_sum
    current_sum="$(_compute_sha256 "$target_file")"
    baseline_sum="$(read_manifest_checksum "$target_dir" "$rel_path")"

    if [[ "$current_sum" == "$shipped_sum" ]]; then
      # Already the shipped content — nothing to do, and no conflict even if
      # the user arrived there by hand.
      installed_files+=("$rel_path")
    elif [[ -n "$baseline_sum" && "$current_sum" == "$baseline_sum" ]]; then
      # FR-3.2: tracked and unmodified — overwrite silently.
      cp "$src_file" "$target_file"
      installed_files+=("$rel_path")
    else
      # FR-3.3: user-modified, or untracked content that predates the install
      # (installing into a populated repository) — offer the new version
      # alongside rather than overwrite.
      cp "$src_file" "${target_file}.prospect-incoming"
      conflict_files+=("$rel_path")
    fi
  done < <(find "$source_dir" -type f -print0)

  # Write manifest and version file (FR-4.1, FR-4.2).
  # Entries cover exactly what this release ships and the installer manages;
  # paths dropped by the release, and files skipped as user content, fall out
  # of tracking.
  write_manifest "$target_dir" "$version" "${manifest_pairs[@]:-}"
  write_version_file "$target_dir" "$version"

  # FR-3.4: Print summary.
  echo "Prospect ${version} installed."
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

  PROSPECT_CONFLICT_COUNT=${#conflict_files[@]}
}

# ── Conflict merge ─────────────────────────────────────────────────────────────

# The merge brief handed to Claude Code. Kept free of quotes so it survives
# being printed as a copy-pasteable command.
PROSPECT_MERGE_PROMPT="Integrate the .prospect-incoming files from the prospect sdd framework update into the current solution. Make sure you understand the changes made and also understand the intent of the current project specific changes. Incorporate the project specific changes into the updated files. The goal is to have the update with the project specifics included. The update takes precedence over the local file structure. If something changed materially during the update (incoming files), make sure to incorporate that change."

# _is_interactive
# True when a terminal is attached. Uses /dev/tty rather than stdin so the
# canonical `curl … | bash` install still counts as interactive.
# Tests override this.
_is_interactive() {
  [[ -z "${PROSPECT_NONINTERACTIVE:-}" ]] || return 1
  [[ -r /dev/tty && -w /dev/tty ]]
}

# _ask_yes_no <question>
# Asks on the terminal; true only on an explicit yes. Tests override this.
_ask_yes_no() {
  local answer=""
  printf '%s' "$1" > /dev/tty
  read -r answer < /dev/tty || return 1
  [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

# propose_merge <target_dir>
# Offers to hand the conflicts to Claude Code, and prints the command whenever
# it does not run it — declined, unavailable, or no terminal attached.
propose_merge() {
  local target_dir="$1"

  if command -v claude > /dev/null 2>&1 && _is_interactive; then
    if _ask_yes_no "  Run Claude Code now to merge the incoming changes? [y/N] "; then
      ( cd "$target_dir" && claude "$PROSPECT_MERGE_PROMPT" )
      return 0
    fi
  fi

  echo
  echo "  To merge them with Claude Code, run:"
  echo
  echo "    claude \"$PROSPECT_MERGE_PROMPT\""
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"

  # Allow tests to verify parsing without triggering network/install.
  if [[ "${PROSPECT_DRY_RUN:-}" == "1" ]]; then
    echo "VERSION_ARG=${VERSION_ARG:-}"
    return 0
  fi

  local version
  version="$(resolve_version "$VERSION_ARG")"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" EXIT

  download_release "$version" "$tmp_dir"

  local source_dir="$tmp_dir/prospect-${version}"
  if [[ ! -d "$source_dir" ]]; then
    source_dir="$tmp_dir"
  fi

  PROSPECT_CONFLICT_COUNT=0
  install_files "$source_dir" "$PWD" "$version"

  if [[ ${PROSPECT_CONFLICT_COUNT:-0} -gt 0 ]]; then
    propose_merge "$PWD"
  fi
}

if [[ "${_PROSPECT_SOURCED:-}" != "1" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
