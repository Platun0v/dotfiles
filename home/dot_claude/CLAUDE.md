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
- **Exception — subagent-driven development.** When running the subagent-driven-development
  workflow (per-task implement→review cycles), subagents MAY create intermediate commits as
  review checkpoints without a per-commit ask — treat them as ephemeral scaffolding, one per
  task. Once the feature is done, squash the whole stack into a SINGLE commit so the history
  keeps no trace of the per-task commits (the repo looks as if those intermediate commits never
  existed). This exception covers only commit + squash inside the workflow; pushing / merging /
  finalizing the squashed result still needs an explicit request. (jj: per-task `jj commit`,
  then `jj squash` the stack into one; git: per-task commits, then `git rebase -i`/`reset --soft`
  to one.)

## Code search tooling
- For symbol/structure lookups — where a symbol is defined, callers/callees, a file's
  outline, "what/where is X", or surveying an area — prefer the codegraph MCP
  (`codegraph_explore`/`_search`/`_node`/`_callers`/`_callees`) and Serena's symbolic
  tools over plain `grep`/`find`. They query a pre-built index, so one call returns the
  verbatim source — far cheaper than grep+read loops.
- Serena's symbolic navigation is backed by the JetBrains IDE here (the `jet_brains_*`
  tools): it needs the project open and indexed in the IDE. codegraph is a standalone
  index that does NOT need the IDE — prefer it when the IDE may not be running, and fall
  back to Serena's IDE tools for live refactors/inspections that need the language server.
- Reserve `grep`/`find` for genuine text scans where no symbol exists: comment markers
  (e.g. `// --- fork: ---`), string literals, config/log text — or when codegraph and
  Serena are both unavailable.

# Memory policy — which store, when

- **Rules** (always-apply behavioral constraints) → this file (global) or a repo-level
  `CLAUDE.md` (project rules). Full text, always loaded. Rules live ONLY in CLAUDE.md.
- **All facts & knowledge** → Serena memories. Project knowledge in `.serena/memories/`;
  cross-project facts under the `global/` prefix. Each project keeps a `core` memory as
  its index and links related/used memories (incl. `global/…`) with `mem:` references.
  Conventions: see Serena memory `global/memory_maintenance`.
- Do **not** use Claude Code native auto-memory (`MEMORY.md`) — superseded by Serena.

When you learn something worth keeping: a behavioral rule → CLAUDE.md; any other
fact/knowledge → a Serena memory (global/ if cross-project, else project). One fact,
one home — update instead of duplicating; never store rules in Serena.

# Serena workflow

Session lifecycle in Serena projects: **`serena-bootstrap`** at the start (activates the
project, loads saved state + relevant memories, reports where work left off) → work →
**`finalize-session`** at the end (distills durable facts, then overwrites the session
snapshot). Start is nudged automatically by the enforcement `SessionStart` hook; the end
is an explicit call — there is no reliable auto-trigger, so finalize before you stop.

Two memory planes — keep them separate:
- **Durable** → Serena memories (`core` + focused, project or `global/`). Strict filter.
- **Transient working state** → `.serena/memories/_session/current.md` only. It is hidden
  from `list_memories` (`ignored_memory_patterns`) and written/read with harness file
  tools, never `read_memory`/`write_memory`. Forward-looking ("how to continue"), not a
  history log. Narrative/history is dropped — there is no claude-mem.

Context here is `claude-code`; modes cannot be switched at runtime (set at startup).
