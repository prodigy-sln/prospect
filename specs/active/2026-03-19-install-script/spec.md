---
id: SPEC-001
title: Install & Update Script
status: active
branch: feature/2026-03-19-install-script
created: 2026-03-19
updated: 2026-03-19
author: Sebastian Grunow
---

# Specification: Install & Update Script

## Goal

Provide a one-liner install/update experience for Prospect via `curl | bash` (Linux/macOS) and PowerShell (Windows), so users can add and maintain the SDD framework in their repositories without manual file copying. Includes a GitHub Actions release pipeline to produce versioned artifacts.

## User Stories

- As a developer, I want to install Prospect with a single command so that I can start using SDD immediately without manual file copying.
- As a developer, I want to choose which toolchains to install (Claude Code, VS Code Copilot, or both) so that I only get what I need.
- As a developer, I want to update Prospect without losing my customizations so that framework updates don't overwrite my project-specific changes.
- As a developer, I want clear notification of conflicts so that I can review and merge framework changes into my customized files.
- As a maintainer, I want a release pipeline so that tagged versions produce installable artifacts automatically.

## Functional Requirements

### Installation Flow

- **FR-1.1**: The bash script (`install.sh`) must work via `curl -fsSL <url> | bash` on Linux and macOS.
  - Acceptance: Script runs on Ubuntu 22+, macOS 13+, and common CI environments without additional dependencies beyond `curl`, `tar`, `bash`.
- **FR-1.2**: The PowerShell script (`install.ps1`) must work via `irm <url> | iex` on Windows.
  - Acceptance: Script runs on Windows 10+ with PowerShell 5.1+ and PowerShell 7+.
- **FR-1.3**: Both scripts must produce identical results (same files installed, same manifest, same version tracking).
  - Acceptance: Running both scripts against the same empty directory produces identical file trees.
- **FR-1.4**: The script must accept an optional version argument (e.g., `install.sh v1.2.0`). If omitted, install the latest release.
  - Acceptance: Specifying a version installs that exact version; omitting installs latest.

### Toolchain Selection

- **FR-2.1**: The script must present an interactive multi-select prompt: Claude Code, VS Code Copilot, or both.
  - Acceptance: User can select one or both; selection determines which files are installed.
- **FR-2.2**: When Claude Code is selected, install: `.claude/skills/`, `.claude/agents/`, `CLAUDE.md`.
  - Acceptance: Only Claude Code files present after install with Claude Code selection only.
- **FR-2.3**: When VS Code Copilot is selected, install: `.github/agents/`, `.github/prompts/`, `.github/instructions/`, `.github/copilot-instructions.md`.
  - Acceptance: Only Copilot files present after install with Copilot selection only.
- **FR-2.4**: Shared files must always be installed regardless of selection: `standards/global/`, `specs/_templates/`, `specs/active/` (directory only), `specs/implemented/` (directory only), `product/` (templates only).
  - Acceptance: Shared directories and templates exist after any selection.
- **FR-2.5**: When run non-interactively (piped input), default to installing both toolchains. Accept a `--claude`, `--copilot`, or `--all` flag to override.
  - Acceptance: `curl ... | bash -s -- --claude` installs Claude Code only without prompting.

### Conflict Detection & Resolution

- **FR-3.1**: On first install (no `.prospect-manifest.json` exists), copy all selected files without conflict checks.
  - Acceptance: Clean install into empty project succeeds with no prompts beyond toolchain selection.
- **FR-3.2**: On update (`.prospect-manifest.json` exists), compare each file's current checksum against the manifest checksum.
  - Acceptance: Unmodified files are overwritten silently; modified files trigger conflict handling.
- **FR-3.3**: When a conflict is detected (user modified a framework file), save the new version as `<filename>.prospect-incoming` alongside the existing file.
  - Acceptance: Original file preserved, incoming file written, user notified with file path.
- **FR-3.4**: After all files are processed, print a summary of conflicts with file paths and suggested resolution.
  - Acceptance: Summary lists all `*.prospect-incoming` files and instructions to diff/merge.
- **FR-3.5**: If `copilot-instructions.md` already exists with non-Prospect content, notify the user and suggest resolving with the AI CLI they selected (e.g., "Run `claude` or `copilot` to merge your existing instructions with Prospect's").
  - Acceptance: Existing `copilot-instructions.md` is never overwritten; user gets actionable merge suggestion.

### Version Tracking & Manifest

- **FR-4.1**: Write `.prospect-version` to the project root containing the installed version tag (e.g., `v1.0.0`).
  - Acceptance: File exists after install; content matches the release tag.
- **FR-4.2**: Write `.prospect-manifest.json` to the project root containing `{ "version": "<tag>", "toolchains": ["claude", "copilot"], "files": { "<relative-path>": "<sha256-checksum>", ... } }`.
  - Acceptance: Every installed file has an entry; checksums match file contents.
- **FR-4.3**: On update, the script must read the existing manifest to determine which toolchains were previously installed and default to the same selection.
  - Acceptance: Re-running the script without flags preserves the original toolchain selection.

### File Categories

- **FR-5.1**: Framework-managed files (overwrite if unmodified): all files in `.claude/skills/`, `.claude/agents/`, `.github/agents/`, `.github/prompts/`, `.github/instructions/`, `specs/_templates/`.
  - Acceptance: Unmodified framework files are updated silently on version bump.
- **FR-5.2**: User-customizable files (conflict-check on update): `standards/global/code-quality.md`, `standards/global/testing.md`, `standards/global/git-workflow.md`, `CLAUDE.md`, `.github/copilot-instructions.md`.
  - Acceptance: Modified customizable files get `.prospect-incoming` treatment.
- **FR-5.3**: User-created content (never touch): `specs/active/*` (contents), `specs/implemented/*` (contents), `product/mission.md`, `product/roadmap.md`.
  - Acceptance: Existing user content in these locations survives install/update unchanged.
- **FR-5.4**: Directory structure must be created even if empty: `specs/active/`, `specs/implemented/`, `product/`.
  - Acceptance: Directories exist after install regardless of content.

### Non-Prospect Content

- **FR-6.1**: The script must never delete files it didn't install. Only add or update files listed in the manifest.
  - Acceptance: Pre-existing non-Prospect files in `.claude/`, `.github/`, or any directory are untouched.
- **FR-6.2**: If the target project already has a `.github/` with non-Prospect content (e.g., workflows, issue templates), leave all non-Prospect files untouched.
  - Acceptance: Existing `.github/workflows/`, `.github/ISSUE_TEMPLATE/`, etc. survive install.

### Edge Cases

- **FR-7.1**: If run in a non-git repository, print a warning ("This directory is not a git repository. Prospect works best with git.") but proceed.
  - Acceptance: Script completes successfully in a non-git directory.
- **FR-7.2**: If the GitHub API is unreachable or rate-limited, print a clear error with retry instructions.
  - Acceptance: Network failure produces actionable error message, not a cryptic shell error.
- **FR-7.3**: The script must be idempotent — running it twice with the same version produces the same result without errors.
  - Acceptance: Second run completes with "Already up to date" message.

### Release Pipeline

- **FR-8.1**: A GitHub Actions workflow (`.github/workflows/release.yml`) must trigger on version tag push (`v*`).
  - Acceptance: Pushing tag `v1.0.0` triggers the workflow.
- **FR-8.2**: The workflow must produce a release artifact (tarball `.tar.gz` and zip `.zip`) containing all distributable files.
  - Acceptance: Artifact contains `.claude/`, `.github/`, `standards/`, `specs/_templates/`, `product/` (templates), `CLAUDE.md`, `README.md`, `install.sh`, `install.ps1`.
- **FR-8.3**: The artifact must include empty directory markers (`.gitkeep`) for `specs/active/`, `specs/implemented/`.
  - Acceptance: Extracting the artifact creates the directory structure including empty spec directories.
- **FR-8.4**: The artifact must NOT include `specs/active/*` content (only the directory), `specs/implemented/*` content, user-created product files, or `.git/`.
  - Acceptance: No spec content or git metadata in the artifact.
- **FR-8.5**: The workflow must create a GitHub Release with the artifact attached and auto-generated release notes.
  - Acceptance: Release visible on GitHub with downloadable artifact and changelog.

## Technical Considerations

### Architecture Decisions

- **Checksum algorithm**: SHA-256 for file integrity checks — universally available on all platforms (`sha256sum` on Linux, `shasum -a 256` on macOS, `Get-FileHash` on Windows).
- **Download mechanism**: Fetch release tarball from GitHub Releases API (`https://api.github.com/repos/<owner>/<repo>/releases/latest`). Fall back to direct URL if API is rate-limited.
- **Temp directory**: Extract tarball to a temp directory, then selectively copy files based on toolchain selection. Clean up temp on exit (trap handler).
- **No external dependencies**: Scripts must work with only built-in OS tools (bash, curl, tar, mktemp for bash; PowerShell built-ins for Windows).
- **Test framework**: Plain bash scripts (`tests/helpers/setup.bash` for assertions and helpers, `tests/run.sh` as runner). No npm, no bats, no external test frameworks.

### Script Structure

```
install.sh / install.ps1
├── Parse arguments (--version, --claude, --copilot, --all)
├── Detect existing installation (read .prospect-manifest.json)
├── Determine version to install (latest or specified)
├── Download and extract release artifact to temp dir
├── Prompt for toolchain selection (if interactive and no flags)
├── For each file in the release:
│   ├── Skip if not in selected toolchains
│   ├── Skip if user-created content location
│   ├── If manifest exists and file in manifest:
│   │   ├── Compare current checksum vs manifest checksum
│   │   ├── If same (unmodified) → overwrite
│   │   └── If different (user modified) → write .prospect-incoming
│   └── If new file (not in manifest) → copy
├── Write .prospect-version
├── Write .prospect-manifest.json (with checksums of installed files)
├── Print summary (installed, updated, conflicts)
└── Clean up temp directory
```

### Release Artifact Structure

```
prospect-v1.0.0/
├── .claude/
│   ├── agents/
│   └── skills/
├── .github/
│   ├── agents/
│   ├── prompts/
│   ├── instructions/
│   └── copilot-instructions.md
├── standards/
│   └── global/
├── specs/
│   ├── _templates/
│   ├── active/.gitkeep
│   └── implemented/.gitkeep
├── product/
│   ├── mission.template.md
│   └── roadmap.template.md
├── CLAUDE.md
├── README.md
├── install.sh
└── install.ps1
```

## Test Strategy

### Unit Tests (plain bash — `tests/bash/*_test.sh`)

- **Checksum logic**: Verify SHA-256 computation matches expected values for known files.
- **Manifest read/write**: Verify JSON serialization/deserialization, version comparison.
- **File categorization**: Verify framework-managed vs. user-customizable vs. user-created classification.
- **Argument parsing**: Verify flag handling (`--claude`, `--copilot`, `--all`, version arg).
- **Version resolution**: Verify latest/specific version fetch, fallback on API failure.

### Integration Tests (plain bash — `tests/e2e/*_test.sh`)

- **Fresh install (bash)**: Run `install.sh` against empty directory → verify all files present, manifest correct, version file correct.
- **Fresh install (pwsh)**: Run `install.ps1` against empty directory → same verification.
- **Update without conflicts**: Modify manifest version, re-run → verify files updated, no `.prospect-incoming` files.
- **Update with conflicts**: Modify a standards file, re-run → verify `.prospect-incoming` created, original preserved.
- **Toolchain selection**: Install Claude-only → verify no `.github/` files. Install Copilot-only → verify no `.claude/` files.
- **Idempotency**: Run install twice → second run shows "Already up to date".
- **Non-interactive mode**: Pipe install with `--claude` flag → verify no prompt, correct files installed.

### Release Artifact Tests (`tests/release/*_test.sh`)

- Verify artifact contains expected files, excludes spec content, includes .gitkeep for empty dirs.

### Test Framework

Plain bash test scripts with a lightweight helper library (`tests/helpers/setup.bash`). No external dependencies (no bats, no npm). Test runner: `tests/run.sh`.

### Test Coverage Target

- All conflict detection, manifest handling, and file categorization paths must be tested.
- Each FR must have at least one corresponding test.

## Existing Code to Leverage

### Similar Features

| Feature | Location | What to Reuse |
|---------|----------|---------------|
| Manual install instructions | `README.md` lines 32-52 | File list and directory structure to replicate |
| Init project structure | `.claude/skills/sdd-init-project/SKILL.md` | Directory creation pattern |

### Patterns to Follow

- GitHub Releases API pattern: standard for CLI tool installers (rustup, nvm, homebrew)
- Manifest-based update pattern: similar to package-lock.json / lockfiles

## Out of Scope

- :x: Project initialization or tech stack configuration (that's `/sdd-init-project`)
- :x: Dependency installation (npm, pip, etc.)
- :x: CI/CD setup beyond the release pipeline itself
- :x: Git hooks or pre-commit configuration
- :x: Uninstall command (can be added later)
- :x: Automatic merge of conflicting files (user must resolve manually or via AI CLI)
- :x: Publishing to package registries (npm, pip, etc.)
- :x: Docker-based installation
- :x: Self-updating of the install script itself (script is always fetched fresh from GitHub)

## Dependencies

### Blocking Dependencies

- None — this is net-new functionality

### External Dependencies

- **GitHub Releases API**: For fetching latest version and downloading artifacts
- **GitHub Actions**: For the release pipeline

## Assumptions

- The Prospect repository will be public on GitHub (required for unauthenticated `curl` downloads).
- Users have `bash` + `curl` + `tar` (Linux/macOS) or PowerShell 5.1+ (Windows) available.
- GitHub API rate limits (60 req/hour unauthenticated) are sufficient for install traffic. If not, the direct download URL bypass handles it.
- Release tags follow semver format: `v1.0.0`, `v1.1.0`, etc.

## Open Questions

- [x] What is the exact GitHub repository URL? → `github.com/prodigy-sln/prospect`

---

## Clarifications

### Session 2026-03-19

- Q: Distribution source? → A: This repo, public GitHub with release tags
- Q: Tool selection? → A: Interactive multi-select (Claude Code, Copilot, both)
- Q: Conflict strategy? → A: Checksum-based with `.prospect-incoming` for conflicts; same for skills/agents
- Q: Version tracking? → A: `.prospect-version` + `.prospect-manifest.json` with per-file checksums
- Q: User content protection? → A: Never touch specs/active, specs/implemented, user-created product files
- Q: Non-git repo? → A: Warn but proceed
- Q: Non-Prospect content? → A: Leave untouched; notify about copilot-instructions.md with AI merge suggestion
- Q: .gitignore? → A: No
- Q: Release pipeline? → A: Part of this spec; GitHub Actions on tag push; artifact excludes spec content but includes empty directories
- Q: Script location? → A: `install.sh` and `install.ps1` at repo root
