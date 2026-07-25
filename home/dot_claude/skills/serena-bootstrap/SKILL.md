---
name: serena-bootstrap
description: Use at the start of work in a Serena project, or when resuming — activates the project, loads the saved session state and the relevant durable memories, and reports where work left off before continuing. Triggers include "продолжим", "resume", "where were we", "на чём остановились", the start of a Serena session, or the SessionStart hook's [serena-bootstrap] directive.
---

# Serena Bootstrap

Prepare a Serena project for work and resume cleanly from the last session. Keep
this **thin and active** — load only what is relevant (progressive disclosure),
do not dump every memory.

## When to use
- Start of a work session in a project that has `.serena/memories/`.
- The SessionStart hook injected a `[serena-bootstrap]` directive with saved state.
- The user says "resume", "продолжим", "на чём остановились".

## Procedure

1. **Activate** — if the project is not already active, `activate_project`.
2. **Sync-conflicts** — run `ls -1 ~/.serena/memories/global/*.sync-conflict-*.md 2>/dev/null`
   (Bash, not Glob: the shell expands `~` reliably). Empty output means clean — say so in the
   **Report** step; do not silently omit it. Any hit means two hosts edited the same global
   memory and Syncthing kept both sides. These files are hidden from `list_memories`, so
   nothing else will ever surface them — carry them into the **Report** step and offer to
   merge. Read them with harness file tools: `read_memory` refuses ignored memories and
   redirects to `read_file`, and `delete_memory` does the same — after merging a conflict,
   remove the leftover file with `rm`, not `delete_memory`.
3. **Index** — `read_memory("core")` and `list_memories()` to see the durable set.
4. **Resume state** — `Read` `.serena/memories/_session/current.md` (the hook may have
   already injected it; read it directly if not). This is the forward-looking snapshot:
   Goal / In progress / Next step / Open questions / Touched.
5. **Selective load** — `read_memory()` ONLY the durable memories that `core` links and
   that are relevant to the current Next step. Do not read the whole set.
6. **Report** — one short paragraph: project, where work left off, and the recorded
   **Next step**, plus any sync-conflicts found in the **Sync-conflicts** step. Ask the
   user to confirm continuing from there (or to redirect).

## Notes
- The session-state file is **not** a Serena memory (hidden by `ignored_memory_patterns`);
  read/write it with harness file tools, never `read_memory`/`write_memory`.
- `~/.serena/memories/` is a Syncthing folder shared between hosts; only `global/` inside it
  is scanned by Serena. Setup and boundaries: Serena memory `global/syncthing-serena-memories`.
- If there is no `_session/current.md`, this is a fresh start — skip **Resume state**
  (step 4), orient from `core`, and proceed.
- For the meaning of contexts / modes / memories / symbolic tools, see
  `references/serena-concepts.md` (read on demand, not every session).
