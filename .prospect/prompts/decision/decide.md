## Phase: Decide

Spawn the `sdd-architect` agent with: the spec path (its decision questions,
discussion findings, and constraints are the drivers), the standing
architecture doc, and the standards paths it names.

Its charge: settle every decision question. Output
`${FOLDER}/decision-record.md`: one ADR per question — context, options
with trade-offs evaluated against the drivers, the decision, consequences,
and the strongest honest argument against it. Mark each BINDING or DEFERRED
(revisit-when). Halt-and-ask applies when a material driver is unknown (one
batched round). Unresolved deadlocks from the discussion go to the user,
never silently settled.

Present the decisions table to the user; after approval, commit
`docs(spec): record [topic] decisions`, then run
`bash .prospect/scripts/sdd-next.sh ${NAME}` and continue.
