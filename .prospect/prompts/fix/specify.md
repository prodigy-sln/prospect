## Phase: Specify (fix)

1. **Reproduce first**: confirm the defect with a concrete run before
   writing anything. If it cannot be reproduced, capture the strongest
   evidence available and say so in the spec.
2. Write `spec.md` from `.prospect/templates/fix.template.md`:
   - **Defect**: observed behavior, expected behavior, reproduction input.
   - **Root cause**: the responsible mechanism, traced in code
     (`file:line`), never guessed from symptoms.
   - **Regression scenarios**: one per distinct wrong behavior, in EARS form
     per `standards/global/scenario-guidelines.md` — these become the
     regression tests.
   - **Out of Scope**: adjacent cleanups observed but not fixed here.
3. Present; after approval set `approved: [today]` in the frontmatter and
   commit `docs(spec): add [defect] fix spec`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
