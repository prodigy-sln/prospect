## Phase: Work (chore)

Non-behavioral change: refactor, tooling, dependency maintenance. No spec
scenarios apply; the full gate is the safety net.

1. `spec.md`'s goal names the change and its boundaries; stay inside them.
   Behavior must not change — a chore that alters observable behavior stops
   and reclassifies (usually as `fix` or `feature`).
2. Make the change. Refactors keep tests green throughout; tooling changes
   prove themselves by running.
3. Run `scripts/sdd-gate.*` to exit 0. A behavior-affecting test change is
   evidence of misclassification — stop and tell the user.
4. Append `## Done` to `spec.md` (date, gate result). Commit with the
   matching type: `refactor:` / `chore:` / `build:`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
