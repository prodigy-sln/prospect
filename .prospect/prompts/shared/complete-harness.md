## Review mode: harness

An external orchestrator owns review and merge. Delete mode: `git rm -r -f`
the spec folder (`-f`: the resolver's `metrics.md` stamp is uncommitted)
and commit `chore: remove spec working folder`. Archive mode: the folder
moved at publish; commit anything still uncommitted in it. End with a clean
working tree. Do not open a PR, merge, or push — the orchestrator merges
this branch. Findings a PR body would list go into your report. Report the
final commit (`git rev-parse HEAD`).
