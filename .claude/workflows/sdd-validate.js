export const meta = {
  name: 'sdd-validate',
  description: 'Spec validation: parallel specialist reviewers, per-finding adversarial verification, deterministic merge',
  whenToUse: 'Invoked by the /sdd-validate skill at rigor high and above. Args: {specFolder, manifest, calibration, passNumber}',
  phases: [
    { title: 'Review', detail: 'correctness, coverage, and quality reviewers in parallel' },
    { title: 'Verify', detail: 'adversarial check of every candidate finding against the code' },
  ],
}

const { specFolder, manifest, calibration, passNumber = 1 } = args
if (!specFolder || !Array.isArray(manifest) || !calibration) {
  throw new Error('sdd-validate requires args: {specFolder, manifest: string[], calibration, passNumber?}')
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
    if (!review) return null

    // Evidence bar: no citation or no concrete failure scenario -> discarded.
    const candidates = review.findings
      .filter(f => f.severity !== 'Info')
      .filter(f => f.file && f.file.length > 0 && f.failure_scenario && f.failure_scenario.length > 0)

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
        ).then(v => ({ ...f, verification: v ? v.verdict : 'plausible', verificationReason: v ? v.reason : 'verifier unavailable' })),
      ),
    )

    return { dimension: d.key, review, findings: verified.filter(Boolean) }
  },
)

const dimensions = results.filter(Boolean)

let findings = dimensions.flatMap(r => r.findings).filter(f => f.verification !== 'refuted')

// Convergence: a re-validation pass only raises Major and above.
if (passNumber >= 2) {
  findings = findings.filter(f => f.severity === 'Blocker' || f.severity === 'Major')
}

const bySeverity = s => findings.filter(f => f.severity === s)
const blockers = bySeverity('Blocker')
const majors = bySeverity('Major')
const minors = bySeverity('Minor')
const reportedMinors = minors.slice(0, 5)

const failedScenarios = dimensions
  .flatMap(r => (r.review.scenarios || []).map(s => ({ ...s, dimension: r.dimension })))
  .filter(s => s.verdict !== 'PASS')

const info = dimensions.flatMap(r => r.review.findings.filter(f => f.severity === 'Info'))

const verdict =
  blockers.length + majors.length + minors.length === 0 && failedScenarios.length === 0 ? 'PASS' : 'FAIL'

log(`Validation pass ${passNumber}: ${verdict} — B${blockers.length} M${majors.length} m${minors.length} (Info ${info.length})`)

return {
  verdict,
  passNumber,
  counts: { blocker: blockers.length, major: majors.length, minor: minors.length, info: info.length },
  findings: [...blockers, ...majors, ...reportedMinors],
  minorOverflow: Math.max(0, minors.length - reportedMinors.length),
  failedScenarios,
  info,
  perDimension: dimensions.map(r => ({ dimension: r.dimension, verdict: r.review.verdict, findings: r.findings.length })),
}
