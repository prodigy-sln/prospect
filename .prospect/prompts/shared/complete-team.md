## Review mode: team

Open the PR: title = feature title; body = what/why/how, validation
verdict, outstanding findings, checklist (gate green · validation PASS ·
docs consolidated · registry line · no out-of-scope changes). Delete mode:
state in the body that the spec folder is removed on finalize.

Stop here — **Finalize** runs on the next invocation after approval:
verify via `gh` that the PR is approved with checks green, `git rm -r` the
spec folder, commit `chore: remove spec working folder`, push,
`gh pr merge --squash`. If branch protection dismissed the approval on that
push, one re-approval of the deletion commit is required.
