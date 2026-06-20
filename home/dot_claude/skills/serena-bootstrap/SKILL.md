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
2. **Index** — `read_memory("core")` and `list_memories()` to see the durable set.
3. **Resume state** — `Read` `.serena/memories/_session/current.md` (the hook may have
   already injected it; read it directly if not). This is the forward-looking snapshot:
   Goal / In progress / Next step / Open questions / Touched.
4. **Selective load** — `read_memory()` ONLY the durable memories that `core` links and
   that are relevant to the current Next step. Do not read the whole set.
5. **Report** — one short paragraph: project, where work left off, and the recorded
   **Next step**. Ask the user to confirm continuing from there (or to redirect).

## Notes
- The session-state file is **not** a Serena memory (hidden by `ignored_memory_patterns`);
  read/write it with harness file tools, never `read_memory`/`write_memory`.
- If there is no `_session/current.md`, this is a fresh start — skip step 3, orient from
  `core`, and proceed.
- For the meaning of contexts / modes / memories / symbolic tools, see
  `references/serena-concepts.md` (read on demand, not every session).
