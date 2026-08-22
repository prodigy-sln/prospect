## Phase: Complete

Prerequisites: the validate phase recorded PASS (and any sign-off it
required has been given); working tree clean. Disposal setting comes from
CLAUDE.md (`spec-disposal: delete | archive` + `retention`).

**Publish** (no PR/merge yet):

1. Run `scripts/sdd-gate.*` once — red = stop.
2. Spec frontmatter: `status: implemented`, `completed: [today]`.
3. Consolidate into `docs/` via the `docs-consolidator` agent (generate
   `docs/INDEX.md` from `.prospect/templates/docs-index.template.md` first
   if missing). Route overflow knowledge — lessons, trap notes, design
   essays from the spec folder — into `docs/`; the registry and task files
   never carry it.
4. Append ONE line to `specs/REGISTRY.md`, **≤50 words**:
   `[folder] · [date] · [work-type]/[rigor] · [tags] · [summary] · [PR/branch]`
   plus a metrics suffix from `metrics.md`: phases · wall-clock.
5. Remaining Minor/Info findings → one tracked issue each (or a PR-body
   list without a tracker).
6. Archive mode: `git mv` the folder to `specs/archive/YYYY/` in the publish
   commit and prune archive folders older than the retention setting.

Then hand off per the review mode below.
