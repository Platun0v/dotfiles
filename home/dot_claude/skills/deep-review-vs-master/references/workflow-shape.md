# Workflow shape

Write this script inline each run rather than maintaining a checked-in `.js`. The
contract lives here; a second file would drift from it. Paths to the brief and the
diffs come in through `args`.

## Where the barrier belongs

Find fans out and **must** meet at a barrier before refute, because dedup needs every
finding at once — two angles routinely report the same defect from different sides, and
refuting both wastes the expensive pass. Refute then fans out again per surviving
finding. That is the one place a barrier earns itself; everywhere else, pipeline.

## Cross-model assignment

Find and refute run on **different models**. Which two matters less than that they
differ — a model verifying its own output confirms its own mistakes. Dedup and synthesis
sit with the refuter.

```js
export const meta = {
  name: 'deep-review',
  description: 'Fan out finders over a diff, dedup, then refute each finding on a different model',
  phases: [{ title: 'Find' }, { title: 'Refute' }],
}

const FIND_MODEL = 'fable'
const REFUTE_MODEL = 'opus'

const FINDING = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['critical', 'major', 'minor'] },
          summary: { type: 'string', description: 'One sentence: what is wrong' },
          failure: { type: 'string', description: 'Concrete input or state -> wrong outcome' },
          quote: { type: 'string', description: 'Verbatim offending code' },
        },
        required: ['file', 'severity', 'summary', 'failure', 'quote'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT = {
  type: 'object',
  properties: {
    state: { type: 'string', enum: ['confirmed', 'refuted', 'needs-evidence'] },
    basis: { type: 'string', description: 'One line. For needs-evidence, name the check that settles it.' },
  },
  required: ['state', 'basis'],
}

phase('Find')
const raw = await parallel(ANGLES.map(a => () =>
  agent(`${a.prompt}\n\nBrief: ${args.brief}\nDiffs: ${args.diffDir}`,
    { label: `find:${a.key}`, phase: 'Find', schema: FINDING, model: FIND_MODEL })
))

// Barrier earns itself here: dedup needs every finding at once.
const deduped = dedupe(raw.filter(Boolean).flatMap(r => r.findings))
log(`${deduped.length} findings after dedup`)

phase('Refute')
const judged = await parallel(deduped.map(f => () =>
  agent(`Try to REFUTE this finding. Default to refuted when the diff alone cannot ` +
        `settle it and no check is nameable.\n\n${JSON.stringify(f)}\n\nDiffs: ${args.diffDir}`,
    { label: `refute:${f.file}`, phase: 'Refute', schema: VERDICT, model: REFUTE_MODEL })
    .then(v => ({ ...f, ...v }))
))

return {
  surviving: judged.filter(Boolean).filter(v => v.state !== 'refuted'),
  refuted: judged.filter(Boolean).filter(v => v.state === 'refuted'),
}
```

## At `max`

Three refuters per finding on distinct lenses — correctness, security, does-it-reproduce
— and a majority of `refuted` kills the finding. Perspective diversity beats redundancy:
three identical skeptics agree with each other, three lenses catch different failures.

Then one sweep round: a fresh find pass told what was already reported, asked only for
what the first pass missed.

## Recall over precision at the gate

A finding marked `needs-evidence` **survives** to the report. The refute pass exists to
kill fabrications, not to kill uncertainty — an unresolved concern with a named check is
worth more to the reader than silence.
