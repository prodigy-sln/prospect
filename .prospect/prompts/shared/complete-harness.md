## Review mode: harness

Delete mode: `git rm -r -f` the spec folder (`-f`: the resolver's
`metrics.md` stamp is uncommitted) and commit `chore: remove spec working
folder`. Archive mode: the folder moved at publish; commit anything still
uncommitted in it. End with a clean tree. Do not open a PR, merge, or push
— the orchestrator merges this branch. Put findings a PR body would list
in your report, and report the final commit.
