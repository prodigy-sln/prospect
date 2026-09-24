## Review mode: harness

An external orchestrator owns review and merge. Delete mode: `git rm -r`
the spec folder and commit `chore: remove spec working folder`. Archive
mode: the folder moved at publish; nothing more. Do not open a PR, merge,
or push — the orchestrator merges this branch. Findings a PR body would
list go into your report. Report the final commit (`git rev-parse HEAD`).
