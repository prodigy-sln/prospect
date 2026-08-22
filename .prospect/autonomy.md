# Autonomy Policy

Consulted by phases running under `/sdd-auto` (`sdd-next.sh --auto`).
Everything not explicitly `auto` stops for the human. Tune per project.

| Decision | Setting |
|---|---|
| work-type classification | stop |
| rigor selection | stop (default recommendation: medium) |
| spec approval | stop |
| scenario-budget overrun (>40) | stop |
| architecture/decision approval | stop |
| discussion deadlocks | stop |
| validation sign-off (high+) | stop |
| publish / merge | stop |

`auto` on a row means: record the decision with rationale in the spec
folder's `decisions.md` and proceed. Budget caps (loop stops when
exceeded): max phases per run: 12 · max wall-clock per run: 4h.
