export const meta = {
  name: 'sdd-validate',
  description: 'Spec validation: parallel specialist reviewers, per-finding adversarial verification, deterministic merge',
  whenToUse: 'Invoked by the validate phase at rigor high and above. Args: {specFolder, manifest, calibration, passNumber}',
  phases: [
    { title: 'Review', detail: 'correctness, coverage, and quality reviewers in parallel' },
    { title: 'Verify', detail: 'adversarial check of each candidate finding — empty when the reviewers report none' },
  ],
}

// The harness may deliver `args` as a JSON string rather than an object.
const input = typeof args === 'string' ? JSON.parse(args) : args
const { specFolder, calibration, passNumber = 1 } = input ?? {}
// Manifest arrives as a string[] or as one newline-joined string; accept both.
const rawManifest = input?.manifest
const manifest = Array.isArray(rawManifest)
  ? rawManifest.map(s => String(s).trim()).filter(Boolean)
  : typeof rawManifest === 'string'
    ? rawManifest.split(/\r?\n/).map(s => s.trim()).filter(Boolean)
    : null
if (!specFolder || !manifest || manifest.length === 0 || !calibration) {
  throw new Error('sdd-validate requires args: {specFolder, manifest: string[] | newline-joined string, calibration, passNumber?}')
}

const REVIEW_SCHEMA = {
  type: 'object',
  required: ['verdict', 'scenarios', 'findings'],
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    scenarios: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'verdict'],
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string', enum: ['PASS', 'FAIL', 'PARTIAL', 'GAP'] },
          location: { type: 'string' },
          reason: { type: 'string' },
        },
      },
    },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'file', 'summary', 'failure_scenario'],
        properties: {
          severity: { type: 'string', enum: ['Blocker', 'Major', 'Minor', 'Info'] },
          file: { type: 'string' },
          line: { type: 'number' },
          summary: { type: 'string' },
          failure_scenario: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['verdict', 'reason'],
  properties: {
    verdict: { type: 'string', enum: ['confirmed', 'refuted', 'plausible'] },
    reason: { type: 'string' },
  },
}

const commonBrief = [
  `Spec folder: ${specFolder} — read spec.md, tasks.md, and architecture.md (if present) from it.`,
  '',
  '### File manifest (review ONLY these files)',
  ...manifest,
  '',
  '### Calibration (governs severity, evidence, volume, skip rules)',
  calibration,
].join('\n')

const DIMENSIONS = [
  { key: 'correctness', agentType: 'sdd-review-correctness' },
  { key: 'coverage', agentType: 'sdd-review-coverage' },
  { key: 'quality', agentType: 'sdd-review-quality' },
]

// Each dimension reviews, then its candidate findings are verified — no
// barrier between dimensions.
const results = await pipeline(
  DIMENSIONS,
  d =>
    agent(`Run your review.\n\n${commonBrief}`, {
      label: `review:${d.key}`,
      phase: 'Review',
      agentType: d.agentType,
      schema: REVIEW_SCHEMA,
    }),
  async (review, d) => {
    if (!review) return { dimension: d.key, dead: true, review: null, findings: [] }

    // Evidence bar: no citation or no concrete failure scenario -> discarded.
    const candidates = review.findings
      .filter(f => f.severity !== 'Info')
      .filter(f => f.file && f.file.length > 0 && f.failure_scenario && f.failure_scenario.length > 0)

    // The Verify phase is conditional: a clean review spawns no verifiers, so
    // say so rather than leaving an empty phase to read as a stuck run.
    const discarded = review.findings.filter(f => f.severity !== 'Info').length - candidates.length
    log(
      candidates.length === 0
        ? `${d.key}: ${review.verdict}, no candidate findings — nothing to verify`
        : `${d.key}: verifying ${candidates.length} finding(s)${discarded > 0 ? `, ${discarded} discarded below the evidence bar` : ''}`,
    )

    // A verifier that dies or errors must degrade its finding to 'plausible',
    // never make it vanish.
    const verified = await parallel(
      candidates.map(f => () =>
        agent(
          [
            'Adversarially verify this code-review finding against the actual code.',
            'Read the cited file and trace the claimed failure scenario. Default to',
            '"refuted" when the scenario cannot actually occur as described.',
            '',
            `Finding: ${JSON.stringify(f)}`,
            '',
            '### File manifest (context)',
            ...manifest,
          ].join('\n'),
          { label: `verify:${d.key}:${f.file}`, phase: 'Verify', schema: VERDICT_SCHEMA, model: 'sonnet' },
        )
          .then(v => ({ ...f, verification: v ? v.verdict : 'plausible', verificationReason: v ? v.reason : 'verifier unavailable' }))
          .catch(e => ({ ...f, verification: 'plausible', verificationReason: `verifier error: ${e && e.message ? e.message : 'unknown'}` })),
      ),
    )

    return { dimension: d.key, dead: false, review, findings: verified.filter(Boolean) }
  },
)

const dimensions = results.filter(Boolean)
const deadDimensions = dimensions.filter(r => r.dead).map(r => r.dimension)
const liveDimensions = dimensions.filter(r => !r.dead)

let findings = liveDimensions.flatMap(r => r.findings).filter(f => f.verification !== 'refuted')

// Convergence: a re-validation pass only raises Major and above.
if (passNumber >= 2) {
  findings = findings.filter(f => f.severity === 'Blocker' || f.severity === 'Major')
}

// Only confirmed findings can block; plausible findings are reported for the
// human but never decide the verdict.
const confirmed = findings.filter(f => f.verification === 'confirmed')
const plausible = findings.filter(f => f.verification !== 'confirmed')

const bySeverity = s => confirmed.filter(f => f.severity === s)
const blockers = bySeverity('Blocker')
const majors = bySeverity('Major')
const minors = bySeverity('Minor')
const reportedMinors = minors.slice(0, 5)

const allScenarios = liveDimensions.flatMap(r => (r.review.scenarios || []).map(s => ({ ...s, dimension: r.dimension })))
// FAIL/PARTIAL block; GAP is an honest abstention (reviewer could not earn a
// verdict) — reported for the human, never counted as a failure.
const failedScenarios = allScenarios.filter(s => s.verdict === 'FAIL' || s.verdict === 'PARTIAL')
const abstentions = allScenarios.filter(s => s.verdict === 'GAP')

const info = liveDimensions.flatMap(r => r.review.findings.filter(f => f.severity === 'Info'))

// Fail closed: a reviewer that never reported cannot be treated as a clean
// review. Any dead dimension forces FAIL with the reason attached.
const verdict =
  deadDimensions.length > 0
    ? 'FAIL'
    : blockers.length + majors.length + minors.length === 0 && failedScenarios.length === 0
      ? 'PASS'
      : 'FAIL'

log(
  `Validation pass ${passNumber}: ${verdict} — confirmed B${blockers.length} M${majors.length} m${minors.length}` +
    ` (plausible ${plausible.length}, Info ${info.length}${deadDimensions.length ? `, dead reviewers: ${deadDimensions.join(',')}` : ''})`,
)

return {
  verdict,
  passNumber,
  deadDimensions,
  counts: { blocker: blockers.length, major: majors.length, minor: minors.length, plausible: plausible.length, info: info.length },
  findings: [...blockers, ...majors, ...reportedMinors],
  plausibleFindings: plausible,
  minorOverflow: Math.max(0, minors.length - reportedMinors.length),
  failedScenarios,
  abstentions,
  info,
  perDimension: liveDimensions.map(r => ({ dimension: r.dimension, verdict: r.review.verdict, findings: r.findings.length })),
}
