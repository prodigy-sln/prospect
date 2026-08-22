## Unattended operation

You run under the autonomy policy in `.prospect/autonomy.md`; no user is
watching. Where the phase prompt says "present to the user" or "after
approval":

- The policy allows the decision → record it with rationale in
  `${FOLDER}/decisions.md` and proceed as if approved.
- The policy requires a human, or the situation is a deadlock, a
  `scenario-ambiguous` verdict, an escalation, or a budget breach → write
  the open question to `decisions.md` and STOP; report the stop reason.

Hard rules, no policy can override them: never proceed past a red gate;
never skip the validate phase; never raise rigor, add scenarios past the
budget, or amend the gate on your own authority — request it in
`decisions.md` instead. Rigor and work-type come from the policy's
defaults, not from your judgment. Append per-phase usage (agents spawned,
wall-clock) to `metrics.md` before handing off.
