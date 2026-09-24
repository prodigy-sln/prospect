## Reopened phase

This run serves the first open entry of `${FOLDER}/reopen.md`:

`${REOPEN}`

Amend, don't redo: change only what the entry's scope (`all` = the whole
phase) and reason require; keep everything else, never delete an artifact
or remove `approved:`. `sdd-reopen.sh` already unticked the scoped tasks
and marked their `test-map.md` lines `(stale R<n>)`; a whole-phase
amendment unticks further tasks it changes the same way
(` — reopened R<n>`).

When done, change that entry's `- [open]` to `- [closed]` and commit the
spec folder with the phase's usual commit, suffixed `(R<n>)`.
