# Procedure gate

What stands between "I noticed a repetition" and "an artifact now exists". The gate is
the intervention; the artifact is just where its output lands.

## What counts as a repetition

A **task shape** carried out in **≥3 sessions across ≥2 projects or hosts**.
Not an error string. Not one incident, however painful.

Diversity is not decoration. Transfer between roles measures **negative** (−4.8 to −7.5
points), so a procedure distilled from a single project reliably improves that project
and reliably fails elsewhere. A card born in one project is not promoted to `global/`
on the strength of that project alone.

The threshold 3 is an interpolation and nothing published attests it: one framework
starts its counter at 2, another has no counter at all, and the one benchmark that
varied it found systematic over-fitting at n=1 (−2.7 on held-out) and real transfer at
n=5 diverse traces. Three is the compromise that fits this user's session rate; treat it
as a dial, not a constant.

## Three checks, in order

### 1. Success

The procedure ran, in this session, and it worked.

This is the most strongly supported element in the whole literature: removing the
success check from a self-authoring agent costs **73% of its performance**, the largest
single ablation measured. No machine can judge "did that debugging go well", so the
judge is the human, here, at finalize time. That is not a workaround — it is the only
honest implementation of the one component that matters most.

### 2. Deduplication

Before writing artifact N+1, compare it against every existing description. Overlap
means **edit the existing artifact**, never add beside it.

The bias toward editing is not taste. Every artifact's description is paid on every
turn, in every one of 8–15 subagents, forever, while its body is nearly free
(progressive disclosure loads the body only on demand). So: **be strict about whether
an artifact exists, lax about how long it is.**

### 3. Abstraction

Turn the transcript into a procedure:

- Replace the specifics with `{named variables}`.
- At least two steps — a single action is a command, not a procedure.
- No overlap with an existing artifact.

A body that reads as prose about what to do regresses into re-derivation: the agent
infers the syntax again, gets confused, re-retrieves, stays confused. Write the literal
pasteable command.

## Which artifact

| Content | Home | Why |
|---|---|---|
| Repeated **task shape** | `~/.claude/skills/<name>/SKILL.md` | The description sits in the system prompt permanently — that is the retrieval mechanism, and it is the difference between a card read in 45 sessions and one read in 1 |
| **Insight / gotcha** | Serena card, with `symptoms:` so a hook can find it | An insight is re-applied, not re-executed |
| Project knowledge | Serena project card | A skill would buy a permanent system-prompt line for something one repo needs |

## Skill frontmatter

```yaml
---
name: <verb-led-name>
description: >
  <What it does.> Use when <trigger>, <trigger>. Phrase triggers as the symptom the
  user will actually type, not the topic.
source_sessions: [<uuid>, <uuid>, <uuid>]
observed_against: "jj 0.3x, go 1.2x"
recheck_after: <YYYY-MM-DD>
stale_when: <the observable condition that makes this wrong>
---
```

`observed_against` / `recheck_after` / `stale_when` cost two lines and carry the whole
value of a temporal knowledge graph. They exist because most of this corpus is
workarounds for other people's bugs — the class that silently expires when upstream
ships a fix. **A stale workaround is worse than a missing one**: it gets retrieved and
believed.

## Retirement

Keep a confirmation count: start at 2, +1 when the artifact is confirmed or extended,
−1 when it is contradicted.

Remove an artifact only when it is **both** low-utility **and** duplicated by another.
A rarely-read unique gotcha card stays: rarity is what a gotcha card is for.

Utility is measurable for free — count `read_memory` calls per card across transcripts
(`~/.claude/projects/<slug>/<uuid>.jsonl`, top level only; the nested `subagents/`
files are separate runs and inflate any per-session count about eighteenfold).
