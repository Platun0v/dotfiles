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
- Serena's symbolic tools run on LSP (`language_backend: LSP` globally, unset in every
  project). Where a project sets `languages: []` — a config repo with no codebase — the
  whole Serena editing layer is inert, including the file-based `replace_content`; edit
  with the harness tools there and reach for codegraph, which needs no language server.
  Details: `mem:global/serena-tool-gotchas`.
- Reserve `grep`/`find` for genuine text scans where no symbol exists: comment markers
  (e.g. `// --- fork: ---`), string literals, config/log text — or when codegraph and
  Serena are both unavailable.

## Testing
- Don't assert human-facing message text (error messages, user-facing copy) in tests —
  it's expected to change and that's fine. Assert the stable, machine-readable part instead:
  HTTP status, the API error `code`, structured / `detail` fields. If a message must be
  checked at all, match only its most stable fragment, never the full string. Exception:
  unit tests of the rendering/formatting layer itself may assert exact strings — there the
  text IS the contract under test.

# Memory policy — which store, when

- **Rules** (always-apply behavioral constraints) → this file (global) or a repo-level
  `CLAUDE.md` (project rules). Full text, always loaded. Rules live ONLY in CLAUDE.md.
- Do **not** create skill-prescribed knowledge artifacts in the repo (`CONTEXT.md`,
  `CONTEXT-MAP.md`, `docs/adr/` from domain-modeling and similar skills) — capture
  glossary/decision content in Serena memories instead. Design docs that the project
  explicitly houses (e.g. `rfc/`, `.claude/specs/`) are unaffected.
- **All facts & knowledge** → Serena memories. Project knowledge in `.serena/memories/`;
  cross-project facts under the `global/` prefix. Each project keeps a `core` memory as
  its index and links related/used memories (incl. `global/…`) with `mem:` references.
  Conventions: see Serena memory `global/memory_maintenance`.
- A **procedure repeated across projects** → a skill in `~/.claude/skills/`, not a memory
  card. Its `description` sits in the system prompt permanently, which is what makes it
  fire; a card must be remembered to be read. The gate before writing one — success, then
  dedup, then abstraction — is in the `finalize-session` skill.
- A rule that **must** fire → a **hook**, not a line here. Adherence decays within a
  session regardless of what this file says; a hook that intercepts the tool call does not.
- Do **not** use Claude Code native auto-memory (`MEMORY.md`) — superseded by Serena.

When you learn something worth keeping: a behavioral rule → CLAUDE.md; a repeated
procedure → a skill; any other fact/knowledge → a Serena memory (global/ if cross-project,
else project). One fact, one home — update instead of duplicating; never store rules in Serena.

Every card carries frontmatter. `description` is written as **the condition under which it
bites**, never as a topic — it is the only thing that decides whether the card is opened
again. A card a failure should surface also carries `symptoms:` with verbatim error strings,
which a hook greps at the moment of failure. A card that works around someone else's bug
carries `observed_against` / `stale_when`: a stale workaround is worse than a missing one,
because it gets retrieved and believed.

Split a card that outgrows ~200 lines; never trim it. Delete only when a card is both
unread and duplicated by another — a rarely-read unique card is doing exactly its job.
Project cards live in no git and no backup, so deletion there is final.

# Serena workflow

Session lifecycle in Serena projects: **`serena-bootstrap`** at the start (activates the
project, loads saved state + relevant memories, reports where work left off) → work →
**`finalize-session`** at the end (distills durable facts, writes the session state, and asks
once whether a procedure repeated across projects has earned a skill). Start is nudged
automatically by the enforcement `SessionStart` hook; the end is an explicit call — there is
no reliable auto-trigger, so finalize before you stop.

Two memory planes — keep them separate:
- **Durable** → Serena memories (`core` + focused, project or `global/`). Strict filter.
- **Transient working state** → `.serena/memories/_session/`, split by how often it is
  rewritten: `current.md` is overwritten whole every time, `progress.md` is appended to and
  deleted when the feature ships. Both are hidden from `list_memories`
  (`ignored_memory_patterns`) and written/read with harness file tools, never
  `read_memory`/`write_memory`. Forward-looking ("how to continue"), not a history log —
  narrative is dropped, there is no claude-mem.

`current.md` carries one `next:` line: the next **physical action**, naming a command or a
`file:line` that exists on disk. Rewrite it after every completed step, not at the end — a
crash, an auto-compaction and walking away all give zero warning, and those are exactly the
interruptions that most need a resume cue. A line that names nothing runnable is worth the
same as no line.

Context here is `claude-code`; modes cannot be switched at runtime (set at startup).
