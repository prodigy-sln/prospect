---
name: sdd-start-issue
description: Resolve an issue ID or description into spec-ready context before running sdd-start
argument-hint: "[issue-id or short description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

Immediately invoke the sdd-start skill with the provided context. This skill is designed to intake an issue ID (e.g., from Jira) or a short feature description, resolve it into the necessary context for spec creation, and then trigger the sdd-start process without requiring additional user input.

1. Create the spec (sdd-start: initiate + shape + specify)
2. After the shape phase produces questions, run sdd-discuss to get stakeholder feedback before writing the spec
3. Update the ticket description to match the spec, then use sdd-architect to create the architecture
4. Use sdd-tasks to create the task breakdown
5. Use sdd-implement to implement the feature
6. Use sdd-validate to validate the implementation

This is an unguided implementation process. You cannot expect user feedback. Work through the tasks until everything is finished. Skills will survive through context compaction. Just continue working.

Use existing project documentation to find the best possible fit for implementation decisions.

Do NOT run sdd-complete in the end.

If required, create a list of manual tasks to finish the feature (e.g., infrastructure setup, third-party configuration, deployment steps).
