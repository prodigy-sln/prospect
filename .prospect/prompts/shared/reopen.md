## Reopened phase

This run serves the first open entry of `${FOLDER}/reopen.md`:

`${REOPEN}`

Amend, don't redo: change only what the entry's scope (`all` = the whole
phase) and reason require; every other artifact line, approval, and ticked
task stays as it is. Never delete an artifact or remove `approved:`.
`sdd-reopen.sh` already unticked the scoped tasks and marked their
`test-map.md` lines `(stale R<n>)`. A whole-phase amendment unticks any
further task it changes the same way (` — reopened R<n>`).

When done, change that entry's `- [open]` to `- [closed]` and commit the
spec folder with the phase's usual commit, suffixed `(R<n>)`. The next
open entry, or the normal pipeline, runs on the next invocation.
