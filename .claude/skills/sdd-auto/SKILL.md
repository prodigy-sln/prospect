---
name: sdd-auto
description: "Drive the pipeline unattended: each phase runs in a fresh subagent under the autonomy policy"
argument-hint: "[folder]"
allowed-tools: Read, Glob, Grep, Bash, Task, Agent, SendMessage, AskUserQuestion
---

# Conductor

Drive `[folder]` through its remaining phases without conversation-history
buildup. You orchestrate; phases do the work in fresh contexts.

Loop:

1. Run `bash .prospect/scripts/sdd-next.sh [folder] --explain`. Exit 2/3 →
   stop and report. Phase `complete` finished → stop and report.
2. Spawn ONE general-purpose subagent: "In this repo, run
   `bash .prospect/scripts/sdd-next.sh [folder] --auto` and follow the
   returned prompt exactly. Report back: phase run, artifacts written,
   commits made, gate result, and any STOP recorded in decisions.md."
3. On its report: STOP recorded, gate red twice for the same cause, or an
   autonomy budget (`.prospect/autonomy.md`) exceeded → halt and present
   `decisions.md`'s open items to the user. Otherwise continue the loop.

Rules: never answer an approval question yourself — the policy file decides
or the loop stops. Never respawn a phase that stopped for a human. Between
iterations report one line: phase · outcome · next. On halt, summarize per
phase: outcome, gate state, open decisions.
