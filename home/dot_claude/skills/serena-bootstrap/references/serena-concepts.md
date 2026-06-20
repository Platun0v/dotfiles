# Serena concepts — quick reference

## Context vs Modes
- **Context** — the environment Serena runs in. Exactly one, fixed at startup
  (`--context`). Here: `claude-code` (disables tools that duplicate Claude Code's
  built-ins; sets `single_project`). Cannot change at runtime.
- **Modes** — refine behavior for a task type; multiple at once. In the installed
  version there is **no runtime mode-switch tool** — modes are set at startup
  (`--mode`/`--add-mode`) or in config, then the MCP server is reconnected.
  Built-ins: editing, interactive, planning, one-shot, onboarding, no-onboarding,
  no-memories, query-projects. Inspect with `get_current_config`.

## Memories (two planes)
- **Durable** — `.serena/memories/` (`core` index + focused, project or `global/`).
  Strict filter: durable, non-obvious, reusable. Progressive disclosure — only names
  are listed up front; read on demand. Conventions live in `global/memory_maintenance`.
- **Episodic / session state** — `.serena/memories/_session/current.md`, hidden from
  `list_memories` via `ignored_memory_patterns`. Transient, overwritten each finalize.
  Written/read with **harness file tools** (ignored memories are not reachable by
  `read_memory`/`write_memory`).

## Symbolic tools
Backed by a language server. **Inert when `languages: []`** (e.g. the dotfiles repo) —
there `get_symbols_overview`/`find_symbol`/`find_referencing_symbols` return nothing;
prefer codegraph or text search. Where a language server is active, prefer symbolic
tools over grep for structure/edits.

## Session lifecycle
`serena-bootstrap` (start) → work → `finalize-session` (end). Start is nudged by the
enforcement SessionStart hook; end is an explicit call (no reliable auto-trigger).
