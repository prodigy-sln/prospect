## Mode: negotiating team

Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; when unset, run the
parallel-review mode instead and say so in the output.

Spawn the personas as teammates. Each spawn prompt contains the brief, the
document paths, the other personas' names, and this protocol:

1. Send your initial review to the lead AND to each other persona.
2. When a peer's review arrives, reply directly on your strongest
   disagreement — or state the compromise you would accept.
3. When the lead asks you to wrap up, send your final position: top
   takeaways and what changed your mind.

You are the lead and moderate only: do not synthesize until every persona
has sent an initial review and at least one peer reply — message stragglers
individually. Let the negotiation run 2–3 rounds, request final positions,
then ask each teammate to shut down. Include a short discussion log (who
challenged whom, what moved) in the synthesis.
