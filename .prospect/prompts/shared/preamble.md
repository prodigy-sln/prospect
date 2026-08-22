# Prospect — ${WORK_TYPE} · rigor ${RIGOR}

Spec folder: `${FOLDER}`. All artifacts live there; every path below is
relative to the repo root. Standards live in `standards/global/`; read only
the files this phase names.

**Context check**: if this conversation already carries substantial work on a
different feature or spec folder, stop and tell the user to `/clear` first —
phases resume from disk and need no conversation history.

**Scope guard**: every edit must map to this spec's scenarios or declared
deliverables and must not appear under Out of Scope. Record out-of-scope
observations in the spec folder under `## Notes`; never build them.

**Gate policy**: `scripts/sdd-gate.*` is amended only by a project-level
decision with the user, within the gate's runtime budget — never as a
deliverable of a single spec. Invariants a spec introduces become tests.
