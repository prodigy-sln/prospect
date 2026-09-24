# Autonomy Policy — harness profile

Consulted by phases an external orchestrator runs with
`PROSPECT_AUTONOMY=.prospect/autonomy-harness.md sdd-next.sh --auto`.
The orchestrator answers every STOP in `decisions.md` and resumes the run;
pair it with `review-mode: harness` so it also owns the merge.

| Decision | Setting |
|---|---|
| work-type classification | set by the caller (`sdd-start --work-type`) |
| rigor selection | set by the caller; raised only via a `rigor_raise` STOP |
| spec approval | auto |
| scenario-budget overrun (past the rigor tier's budget) | stop |
| architecture/decision approval | auto |
| discussion deadlocks | stop |
| validation sign-off (high+) | auto on PASS |
| publish / merge | auto |

`auto` on a row means: record the decision with rationale in the spec
folder's `decisions.md` and proceed. Budget caps (loop stops when
exceeded): max phases per run: 12 · max wall-clock per run: 4h. The
orchestrator enforces its own phase, rewind, time, and cost budgets on top.
