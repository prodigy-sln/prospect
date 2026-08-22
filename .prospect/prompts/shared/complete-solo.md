## Review mode: solo

No external review loop. Delete mode: `git rm -r` the spec folder in a
final commit (`chore: remove spec working folder`) so the branch carries
its own cleanup, then merge to main — `gh pr merge --squash` when the
project uses PRs as a record (create it, merge immediately), plain squash
merge when it doesn't. Archive mode: the folder moved at publish; just
merge. Report the merge commit.
