# Requirements Gathering: Install & Update Script

## Initial Context
Users need a simple one-liner (bash+curl / pwsh) to install and update the Prospect SDD framework in their repositories. The script should handle first-time installs, updates with conflict detection, and save conflicting files as *.incoming or similar.

## Codebase Analysis

### Distribution Model
- **57 distributable files** across 15 directories
- All files are plain markdown — no build step needed

### Framework-managed files (safe to overwrite on update)
- `.claude/skills/` (13 skill files)
- `.claude/agents/` (6 agent files)
- `.github/agents/` (16 agent files)
- `.github/prompts/` (11 prompt files)
- `.github/instructions/sdd-context.md`
- `.github/copilot-instructions.md`
- `specs/_templates/` (2 template files)

### User-customizable files (conflict detection needed)
- `standards/global/code-quality.md` — may be customized for tech stack
- `standards/global/testing.md` — may be customized for tech stack
- `standards/global/git-workflow.md` — may be customized
- `CLAUDE.md` — has Tech Stack section users fill in

### User-created content (never overwrite)
- `specs/active/` — in-progress specs
- `specs/implemented/` — completed specs
- `product/mission.md`, `product/roadmap.md` — user-created from templates

### Existing install instructions
- README.md documents manual `cp -r` commands (lines 32-52)
- No existing scripts — this is net-new

### Versioning
- No version tracking exists yet — need a mechanism for update detection

## Q&A Session

### Session 2026-03-19

**Q1: Distribution source?**
A: This repo (prodigy-sln/prospect). Public GitHub repo with release tags.

**Q2: Tool selection?**
A: Interactive multi-select. User chooses: Claude Code, VS Code Copilot, or both.

**Q3: Conflict strategy for user-customizable files?**
A: Checksum-based. First install: copy everything. Update: compare current file checksum against manifest — if user modified, save new version as `*.prospect-incoming` and notify. If unmodified, overwrite silently. Same approach for skills/agents — use manifest to detect user modifications.

**Q3b: Manifest format?**
A: `.prospect-manifest.json` tracking `{ file: checksum }` for every installed file. Enables detecting user modifications vs. framework originals.

**Q4: Version tracking?**
A: `.prospect-version` file at project root. Tracks installed version (matches GitHub release tag).

**Q5: User content protection?**
A: Confirmed. Never touch: `specs/active/`, `specs/implemented/`, `product/mission.md`, `product/roadmap.md`. Templates and framework files are updatable.

**Q6a: Non-git repo?**
A: Warn but proceed.

**Q6b: Non-Prospect content in .claude/.github?**
A: Leave untouched (additive-only). If `copilot-instructions.md` already exists, notify user and propose resolving with AI using whichever CLI they selected (claude/copilot).

**Q6c: .gitignore updates?**
A: No.

**Q7: Release pipeline?**
A: Part of this spec. GitHub Actions workflow that creates releases with tags. Artifact is a tarball/zip of distributable files (excluding `specs/active/*` content but ensuring directories exist). Install script fetches latest release (or specific version) via GitHub API.

**Q8: Script location?**
A: `install.sh` and `install.ps1` at repo root. README one-liner: `curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash`

## Visual Assets
[N/A — CLI tool]
