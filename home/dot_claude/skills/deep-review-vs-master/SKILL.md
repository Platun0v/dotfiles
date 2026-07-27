---
name: deep-review-vs-master
description: Deep review of a change set before it ships — fan out finders over a project brief, then refute every finding with a different model so only survivors are reported. Use when the user asks to review changes or a diff against master/main/trunk, to review an MR or PR, to review a commit stack starting from a given revision, or asks for a hard, thorough or pre-commit review. Russian triggers — «ревью изменений», «review относительно master», «ревью MR», «жёсткий ревью», «проверь стек перед коммитом».
---

# Deep review vs master

A finding is not a finding until it **survives** an independent attempt to kill it.
Two mechanisms carry that: a **brief** that tells finders what this project already
knows, and a **refute** pass run by a different model than the one that found it.

Without the brief, finders re-report conventions as bugs. Without refute, plausible
fabrications reach the report and cost more trust than the review earns.

## Step 1 — Scope

Resolve what is under review, and echo it back before doing anything expensive.

- No argument → the current stack against the trunk. Detect the VCS first:
  `jj log -r 'trunk()..@'` where a `.jj` directory exists, otherwise
  `git log --oneline <trunk>..HEAD`. Four of this user's repos are jj-colocated and
  report a detached `HEAD` to git — trust `jj`, not `git rev-parse --abbrev-ref HEAD`.
- An argument that names a revision, revset, range, branch, MR or PR → use it verbatim.
- Trunk is not always `master`: read it from the repo (`jj bookmark list`, or
  `git symbolic-ref refs/remotes/origin/HEAD`).

**Done when:** you have printed the resolved range, the ordered commit list
(change-id or hash + subject), and the diffstat totals.

## Step 2 — Brief

Assemble, into one scratch file, what this project already knows. This is the step
that separates a review from a code-reading exercise, and it is the step most often
skipped.

Gather:
- **Conventions** — repo `CLAUDE.md` and `~/.claude/CLAUDE.md`.
- **Touched territory** — for each subsystem the diffstat touches, the matching Serena
  memories (`architecture/*`, `subsystems/*`, `domain/*`). Use `list_memories` then read
  only what the diff actually touches.
- **Invariants** — the rules that are not derivable from the code, wherever the project
  keeps them (`architecture/invariants`, RFC/spec directories, `.claude/specs/`).
- **Already-fixed traps** — gotcha memories for this project and `global/`. Finders read
  these to verify the fix is present rather than to re-report the trap.

**Done when:** the scratch file exists and every subsystem in the diffstat is either
represented in it or explicitly noted as having no recorded knowledge.

## Step 3 — Export diffs

Write per-commit diffs and the full diff to scratch as files. Finders read files;
they do not re-run VCS commands and they do not share your shell.

**Done when:** `full.diff`, `full.stat`, and one `NN-<id>.diff` per commit exist.

## Step 4 — Find

Fan out finders over the brief and the diffs with the Workflow tool. Angles by tier
are in [`references/finder-angles.md`](references/finder-angles.md); the canonical
script shape is in [`references/workflow-shape.md`](references/workflow-shape.md).

Each finder returns structured findings: `file:line`, what breaks, the concrete input
or state that triggers it, and a verbatim quote of the offending code.

**While the fan-out runs, leave the main session idle.** Messages and tool calls in
the parent interrupt background agents and force retries — this cost a full run once.

**Done when:** every angle for the chosen tier has returned or is explicitly recorded
as failed.

## Step 5 — Refute

Every finding goes to a fresh agent **on a different model than the one that found it**,
instructed to kill it. Correlated errors are the failure this defends against: a model
verifying its own output confirms its own mistakes.

The refuter answers three states, never two: **confirmed** (it reproduces),
**refuted** (the concern does not hold, with the reason), **needs-evidence** (cannot be
settled from the diff alone — name the check that would settle it).

Findings that survive proceed. Refuted findings go into the report's refuted section,
because knowing what was checked and dismissed is what stops the next review from
raising it again.

**Done when:** every finding carries one of the three states and a one-line basis.

## Step 6 — Report

In this order:

1. **Verdict** — ship / ship with fixes / do not ship, one line, no hedging.
2. **Survivors by severity** — `file:line`, the failure, the triggering input, the quote.
3. **Per-commit notes** — only where a specific commit carries a specific problem.
4. **Deviations** — where the change departs from a convention or invariant in the brief.
5. **Refuted** — one line each, with why.

**Done when:** every finding from Step 5 appears in exactly one section.

## Effort tiers

| Tier | Finders | Refuters per finding | Sweep |
|---|---|---|---|
| `quick` | correctness core only | 1 | no |
| `standard` (default) | core + concurrency + project-specific | 1 | no |
| `max` | all angles | 3, majority kills | yes |

## Resume

Workflow runs persist. On a limit or a crash, re-invoke with
`{scriptPath, resumeFromRunId}` — unchanged agents replay from cache and only the
failed ones re-run. Before diagnosing an empty result, read `journal.jsonl` in the
run's transcript directory: it records what each agent actually returned.
