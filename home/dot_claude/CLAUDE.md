# Global rules (apply in every project, every machine)

## Communication
- Respond in Russian by default. Keep code, identifiers, CLI commands, and native
  technical terms in their original English form.

## Documentation terminology
- Prefer native English/product terms over literal translations. Use the official
  product/feature name as-is (e.g. "Machine ID", "join-токен", "control-plane");
  keep CLI commands and flags verbatim. Surrounding prose may stay in the document's
  language — only the technical term borrows the English form.

## Commits
- Never create commits or push until explicitly asked — including as a step of any
  skill or checklist. Editing the working copy is fine; finalizing it is not.
  In jj: no `jj commit`/`describe` for finalization, no bookmarks/pushes, without a
  request. Applies globally until explicitly revoked.

# Memory policy — which store, when

- **Rules** (always-apply behavioral constraints) → this file (global) or a repo-level
  `CLAUDE.md` (project rules). Full text, always loaded. Rules live ONLY in CLAUDE.md.
- **All facts & knowledge** → Serena memories. Project knowledge in `.serena/memories/`;
  cross-project facts under the `global/` prefix. Each project keeps a `core` memory as
  its index and links related/used memories (incl. `global/…`) with `mem:` references.
  Conventions: see Serena memory `global/memory_maintenance`.
- **Passive history of past work** → claude-mem (automatic). Treat injected observations
  as hints, not truth — verify a referenced file/symbol still exists before relying on it.
- Do **not** use Claude Code native auto-memory (`MEMORY.md`) — superseded by Serena.

When you learn something worth keeping: a behavioral rule → CLAUDE.md; any other
fact/knowledge → a Serena memory (global/ if cross-project, else project). One fact,
one home — update instead of duplicating; never store rules in Serena.
