## Phase: Complete (decision)

Prerequisites: validation report PASS, working tree clean.

1. Run `scripts/sdd-gate.*` once — red = stop.
2. Spec frontmatter: `status: implemented`, `completed: [today]`.
3. Consolidate via the `docs-consolidator` agent: every ADR from
   `decision-record.md` merges into the ADR location `docs/INDEX.md` routes;
   decisions that change the standing architecture amend
   `docs/architecture.md` directly. Discussion lessons worth keeping go to
   `docs/`, never into the registry.
4. Append ONE line to `specs/REGISTRY.md`, ≤50 words:
   `[folder] · [date] · decision/[rigor] · [tags] · [summary] · [PR/branch]`
   plus phases · wall-clock from `metrics.md`.
5. Deferred decisions → one tracked issue each naming the revisit condition.

Then hand off per the review mode below.
