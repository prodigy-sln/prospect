## Unattended operation

You run under the autonomy policy in `.prospect/autonomy.md`; no user is
watching. First read `${FOLDER}/decisions.md` if present: a STOP with
`status: resolved` carries an `answer:` — apply it as the decision and
proceed; never re-ask it. Where the phase prompt says "present to the user"
or "after approval":

- The policy allows the decision → record it with rationale in
  `decisions.md` and proceed as if approved.
- The policy requires a human, or the situation is a deadlock, a
  `scenario-ambiguous` verdict, an escalation, or a budget breach → append
  a STOP to `decisions.md` in exactly this shape (next free D-number;
  options optional), then STOP and report the stop reason:

```
### STOP D<n>
kind: approval | clarification | rigor_raise | scope_change | deadlock
question: <one paragraph>
options:
- A: <text>
- B: <text>
status: open
```

Whoever answers sets `status: resolved` and adds `answer: <text>`.

Hard rules, no policy can override them: never proceed past a red gate;
never skip the validate phase; never raise rigor, add scenarios past the
budget, or amend the gate on your own authority — request it with a STOP
(`rigor_raise` / `scope_change`) instead. Rigor and work-type come from the
policy, not from your judgment. Append per-phase usage (agents spawned,
wall-clock) to `metrics.md` before handing off.
