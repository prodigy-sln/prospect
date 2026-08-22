---
name: sdd-next
description: "Resolve and run the next pipeline phase for the active spec folder"
argument-hint: "[folder] [--phase name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, Agent, SendMessage, Workflow, AskUserQuestion
---

# Next Phase

Run `bash .prospect/scripts/sdd-next.sh` with the given arguments and
follow the returned prompt exactly — it is the complete instruction set for
the resolved phase.

- Exit 2: do what the message says (run `/sdd-start`, or name one of the
  listed folders explicitly).
- Exit 3: report the resolver message to the user verbatim; do not
  improvise a phase.

The header lines (`folder`, `work-type`, `rigor`, `phase`) are facts; never
substitute your own judgment for them. When the prompt ends by invoking the
resolver again, do so in the same session unless it announced a user stop.
