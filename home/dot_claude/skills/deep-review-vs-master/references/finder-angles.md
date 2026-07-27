# Finder angles

One agent per angle. Each reads the brief and the diffs, and returns structured
findings. Angles are peers — order carries no meaning.

## Correctness core — every tier

- **Line-by-line** — read the diff as written, not as intended. The single highest-yield
  angle, and the one that feels least clever.
- **Removed behaviour** — for every deleted or replaced line, name what used to happen
  and who depended on it. Deletions hide more defects than additions.
- **Cross-file tracer** — follow each changed symbol to its callers and its callees.
  Use codegraph rather than grep; the index is already built.
- **Language pitfalls** — the traps of the language actually in the diff:
  - Go — nil map writes, loop-variable capture, map iteration order where order is
    load-bearing, mutating a value obtained from a shared cache, `err` shadowing.
  - Python — mutable default arguments, import-time side effects, `and`/`or` between
    library expression objects (SQLAlchemy clauses silently collapse to one operand),
    late binding in comprehensions.
  - TypeScript — `any` re-entering a typed boundary, non-null assertions on external
    data, unawaited promises, structural types accepting extra fields.
- **Wrapper masking** — a decorator, proxy or middleware that swallows an error,
  rewrites a status, or changes a default the caller still assumes.

## Concurrency and lifecycle — standard and above

- Locks held across a blocking call, a network round-trip, or a sleep.
- Goroutines, tickers, watchers and subscriptions with no termination path.
- Background loops racing the handler that owns the same state.
- Ordering assumptions between a producer and a consumer that nothing enforces.

## Project-specific — standard and above

These angles come from the **brief**, not from this file. Instantiate one agent per
invariant the brief records, each asking a single question:

- **Convention deviation** — does the change follow this project's established pattern
  for adding a resource, an endpoint, a migration, a config key?
- **Isolation** — where the project maintains a boundary (a fork's marker comments and
  minimal-diff rule, a layering rule, a module that must not import another), is it
  intact?
- **Reversibility** — where the project promises that turning a feature off restores
  prior behaviour exactly, does it?
- **Spec conformance** — code against the RFC, spec or changelog the brief supplied.
  A deliberate deviation is fine; an undocumented one is a finding.

For a project whose brief records no invariants, this group is empty. Say so rather
than inventing angles.

## Per-commit

One agent per commit, asking whether the message matches the content and whether the
commit stands alone.

- `standard` — sample, capped at a handful.
- `max` — every commit.

## Cleanup — max only

Reuse, simplification, efficiency, and altitude. These produce the most findings and
the least value; they run last and only at `max`, so they never crowd out correctness.

## Mechanical — cheap tier, runs in background

Build, vet, lint and the tests of the touched packages. Run it on the cheapest model,
or as plain shell — it needs no reasoning, only a verdict and the failing output.
