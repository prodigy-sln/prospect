## Phase: Edit (docs)

The deliverable is documentation; no test machinery applies.

1. Read `docs/INDEX.md`; route every change through it. `docs/` describes
   the system as built — future concepts belong in specs and
   `product/roadmap.md`, never here.
2. Make the changes listed in `spec.md`'s goal. Merge, don't duplicate;
   match each file's structure and tone; update the INDEX registry and
   Sources for files added or repurposed.
3. Gate: run the documentation stages of `scripts/sdd-gate.*` (link
   integrity, format) when the gate defines them, else verify links and
   INDEX consistency yourself and record how.
4. Append `## Published` to `spec.md` (date, files touched). Commit
   `docs: [summary]`.

Then run `bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
