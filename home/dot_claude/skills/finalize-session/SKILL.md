---
name: finalize-session
description: Use when wrapping up a work session, reaching a milestone, or when the user asks to finalize / save / remember / checkpoint / persist the session — runs three tracks — (1) distills durable facts into Serena memory, (2) writes the session state so the next session resumes from a concrete next action, and (3) turns a procedure repeated across projects into a skill. Triggers include "finalize session", "финализируй сессию", "сохрани состояние", "save this to memory", "запомни", "сохрани в память", "checkpoint", "заканчиваем", end-of-session summary, "what's worth keeping from this session".
---

# Finalize Session

## Overview

Review the current conversation, extract the few facts that are worth recalling in
a future session, and persist them to **Serena memory** — correctly routed, deduped,
and indexed. The hard part is judgment: most of a session is noise. Save the
decisions and durable knowledge; drop everything re-derivable, transient, or that
belongs in a different store.

**Core principle: one fact, one home. Update before you create. When in doubt, leave it out.**

## When to use

- End of a work session, or a natural milestone (a phase finished, a decision locked).
- The user asks to save / remember / checkpoint / persist something.
- You just made or discovered something non-obvious that future-you would want.

**When NOT to use:** mid-task with nothing settled yet; or when the only thing to
record is a behavioral rule (that goes in CLAUDE.md, not here — see routing below).

## Step 0 — Load the source of truth (always, first)

Conventions can change; do not work from memory of them. Read, in order:

1. `read_memory("global/memory_maintenance")` — the authoritative rules for all memories.
2. `read_memory("core")` — this project's index: what already exists and how it links.
3. `list_memories()` — confirm the current set of memory names.

If `core` does not exist, this project has no index yet — you will create one.

## Step 1 — Harvest candidates

Scan the conversation for things that changed your understanding or the project:

- **Durable invariants / constraints and their rationale** — the standing truth, not
  the event of deciding. The *why* and the rejected alternative are the valuable part.
- **Non-obvious constraints** discovered the hard way (a corporate CA, an API quirk, a
  device limitation, a flag that must be set).
- **Stable maps / structure** worth not re-deriving (module layout, key id-strings,
  a toolchain setup).
- **Project state / next step** that isn't obvious from code or git.

**Reframe every "we decided X" into a standing truth: "X is / must be Y, because Z."**
If it won't reframe — if the honest form is "we did X today" or "X for now, until
later" — it's history or a temporary tactic, not a fact. Drop it.

Write a quick candidate list. Err on the side of listing, then filter hard in Step 2.

## Step 2 — Route and filter (the discipline step)

For every candidate, pick its home. Most candidates die here.

**Most sessions yield zero keepers — that is the normal, correct outcome.** Saving
something every session is how memory rots. If nothing passes the test below, save
nothing and say so. Do not manufacture a memory to feel productive.

| Candidate is… | Goes to | Not Serena? |
|---|---|---|
| A behavioral **rule** ("always X", "never Y") | **CLAUDE.md** (global or repo) | ✅ skip |
| Passive "what we did" history / play-by-play | **drop** (nowhere — not stored) | ✅ skip |
| A **one-off / tactical / "for now" decision** (obsolete once the change merges) | **drop** (nowhere) | ✅ skip |
| Trivially re-derivable from code, git, or `--help` | nowhere | ✅ skip |
| Transient session chatter, scratch reasoning | nowhere | ✅ skip |
| A reusable **fact / knowledge**, project-specific | Serena **project** memory | save |
| A reusable fact/knowledge, **cross-project** | Serena **`global/`** memory | save |

The "worth keeping" test — a survivor must pass all **four**:
- **Durable** — still true and useful next session, not just right now.
- **Survives the code** — still true *after this change is merged*. A value obsoleted
  once the diff lands ("750ms for now", "144px until the settings screen") fails this:
  it is tactical, not durable — no matter how it's labelled ("architectural", "big decision").
- **Non-obvious** — not re-derivable by reading the code or `git log`.
- **Reusable** — you'd actually recall it to do future work.

**Quick check:** name the future question this memory answers. Can't name one? It's clutter — skip.

If the user insists on saving a rule or an "obvious" fact, do not dump it raw — ask
what was *non-obvious* about it and save that distilled fact instead.

## Step 3 — Update before you create

For each survivor, check the existing memories from Step 0:

- **Covered by an existing memory?** → `edit_memory` to update it. Never create a
  near-duplicate. One fact, one home.
- **New, distinct topic?** → `write_memory` with a dense, kebab-case, `/`-grouped name
  (e.g. `architecture/overlay-pipeline`, `phase2-xposed-hooks`).
- **Stale / now-wrong memory?** → fix or `delete_memory` it. `rename_memory` keeps
  `` `mem:NAME` `` references in sync.

**Format:** dense factual agent-notes, one focused topic per memory, no filler. Link
related memories with backticked `` `mem:NAME` `` (project or `global/`).

**Every card carries frontmatter**, and `description` is the one line that decides
whether it is ever opened again:

```yaml
---
description: <WHEN this bites — the condition, not the topic>
verified: <YYYY-MM-DD>
symptoms: ["verbatim error string"]        # cards a failure should surface
observed_against: "<tool + version>"       # cards that work around someone else's bug
recheck_after: <YYYY-MM-DD>
stale_when: <the observable condition that makes this wrong>
---
```

Write `description` as the symptom the reader will actually be looking at.
"How Serena's replace_content handles escapes" is a topic and will not be found;
"replace_content writes a literal backslash-n into the file in regex mode" is a
condition and will.

**Size:** a card over ~200 lines gets **split**, never trimmed. There is no backup for
project cards — splitting loses nothing, trimming is irreversible.

**Removal:** delete only when a card is both unread and duplicated by another. A rarely
read but unique card stays.

## Step 4 — Keep `core` current

`core` is the project's index and entry point. After adding / removing / renaming
memories, update `core` so it links every project memory and any relied-on global
memory via `` `mem:…` `` references, and reflect the new project status/next-step.
A memory not reachable from `core` is a memory you'll forget exists.

## Step 5 — Report

Tell the user concisely: which memories you **created**, **updated**, or **deleted**
(by name), and what you deliberately **skipped** and why (e.g. "rule → belongs in
CLAUDE.md", "re-derivable from code"). The skips are how the user catches a
mis-route.
Then quote the **`next:` line verbatim** (Track 2), so the user can catch a resume
target that names nothing runnable. If Track 3 produced a skill, name it and say which
three sessions it came from; if it produced nothing, say nothing about it.

## Step 6 — Snapshot session state (Track 2, ALWAYS)

Independently of whether any durable memory was saved, write the transient session
state so the next session resumes cleanly. These are **not** Serena memories — they are
ignored by `list_memories` (pattern `_session/.*`) and written with the **harness
`Write` tool** (Serena memory tools cannot touch ignored memories).

Two files, split by how often they are rewritten. Keeping them in one file destroys the
half that should have survived.

### `_session/current.md` — overwritten whole, every time

```markdown
# Session state — <project>
updated: <YYYY-MM-DD>

## Goal
<what the work is about, 1–2 lines>

## Active
<the one task in hand>

next: <when> — <exact command or file:line> — <the one fact that makes it non-obvious>

## Suspended
- <key> — <one line> — next: <its own resume line>

## Waiting on a human
- <the question, or omit this section entirely>

## Touched outside VCS
- <memory edits, scratchpad artefacts, files outside the repo, user decisions like
  "do not revert this" — everything `jj status` and `jj log` already say is omitted>
```

### The `next:` line is the load-bearing part

It is **prospective**: the next physical action, not a summary of what happened. It
names something that exists on disk — a command you could paste, or a `file:line`.

```
next: now — run `uv run pytest tests/api/test_tokens.py -k expiry` — it fails at
      test_tokens.py:88 comparing a tz-naive datetime to an aware one
next: when the arch host is up — `jj edit ptuvwxyz && make lint` — nilaway is the only
      linter that reproduces it, golangci-lint alone is green
```

Weak forms to rewrite rather than ship: `continue the token refactor` restates the goal;
`pick this up later` names no observable trigger. A line naming nothing that exists on
disk measures the same as no line at all.

**Write it after every completed step, not only here.** A crash, an auto-compaction and
a user walking away all give zero warning — the suspensions that most need a resume line
are exactly the ones this step never sees.

### `_session/progress.md` — appended, never overwritten

Delete it when the feature ships. It carries what survives a session boundary without
being a durable fact:

```markdown
## <feature>
- [x] done
- [ ] outstanding
- rejected: <option> — <why>
```

The `rejected:` lines pay for themselves: without them a fresh agent proposes the
option you already dismissed.

### Rules

- **Always** write `current.md` on finalize, even when Track 1 saved zero memories.
- **Overwrite** `current.md`; **append** to `progress.md`.
- If `<project>` has no `.serena/memories/` yet, create `_session/` first.

## Step 7 — Procedure track (Track 3, ask once)

One question, at the end:

> Did I today carry out a procedure I have already carried out **in another project or
> on another host** — and did it work?

Almost always the answer is no, and this step ends here. When it is yes, a repeated
procedure is worth an artifact, and the gate that decides is in
[`references/procedure-gate.md`](references/procedure-gate.md).

Repeated **task shapes** become skills; repeated **facts** stay memory cards. The unit
follows the content: a routine you re-execute is a skill, an insight you re-apply is a
card.

## Common mistakes

| Mistake | Fix |
|---|---|
| Saving a behavioral rule into Serena | Rules live only in CLAUDE.md. Skip it here. |
| Hand-writing "what we did" history | History is not stored. Forward-looking state goes to the session snapshot (Track 2); narrative is dropped. |
| Creating a 2nd memory for an existing topic | `edit_memory` the existing one. One fact, one home. |
| Dumping the whole session summary as one memory | Split by topic; save only survivors of Step 2. |
| Saving a temporary / "for now" decision | Obsolete once merged — fails "survives the code". Skip; at most a one-liner in `core` next-step. |
| Saving it because it was hard / took hours | Effort ≠ durability. Re-run the four-part test on the fact itself. |
| Saving facts re-derivable from code/git | Skip. Memory is for the non-obvious. |
| Forgetting to update `core` | Orphaned memories are lost. Always re-index. |
| Project fact written to `global/` (or vice-versa) | Route by scope: cross-project → `global/`, else project. |

## Red flags — stop and re-route

- "I'll save this rule to memory so I remember it" → CLAUDE.md, not Serena.
- "Let me write down everything we did today" → history is not stored; save only durable facts.
- "I spent hours on this, it must be worth saving" → effort ≠ durability. Re-run the four-part test.
- "It's an architectural / big decision" — but it's marked *temporary* / *for now* → tactical, fails "survives the code". Skip.
- "I can't name the future question this answers" → then it's clutter. Skip.
- "I'll make a new memory for this" (without checking existing) → list first, update if covered.
- "Close enough, I'll skip updating core" → don't; re-index every time.
