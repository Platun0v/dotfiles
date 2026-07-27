#!/usr/bin/env bash
# Ad-hoc test for memory-symptom-lookup.sh. Exits non-zero on first failure.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/memory-symptom-lookup.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $1"; exit 1; }

g="$tmp/global"
mkdir -p "$g"

cat > "$g/bash-tool-runs-zsh.md" <<'EOF'
---
description: "Bash-инструмент исполняет zsh, а не bash"
verified: 2026-07-27
symptoms:
  - "no matches found:"
  - "integer expression expected"
---
# body
EOF

# A card that declares it has no error signature must never match.
cat > "$g/silent-drift.md" <<'EOF'
---
description: "молчаливый дрейф, строки ошибки не существует"
symptoms: []   # deliberately empty
---
# body
EOF

run() { printf '%s' "$1" | SERENA_GLOBAL_MEMORIES="$g" bash "$HOOK"; }

# A: error text contains a listed symptom -> card surfaced with its description
out="$(run '{"hook_event_name":"PostToolUseFailure","tool_response":"(eval):1: no matches found: *.md(N)","cwd":"/nonexistent"}')"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 || fail "A: no additionalContext"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'mem:global/bash-tool-runs-zsh' || fail "A: card name missing"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'исполняет zsh' || fail "A: description missing"

# B: unrelated error -> silence, not noise
out="$(run '{"hook_event_name":"PostToolUseFailure","tool_response":"connection refused","cwd":"/nonexistent"}')"
[ -z "$out" ] || fail "B: expected empty stdout, got: $out"

# C: match is case-insensitive and works from tool_input.command too
out="$(run '{"hook_event_name":"PostToolUseFailure","tool_input":{"command":"test INTEGER EXPRESSION EXPECTED"},"cwd":"/nonexistent"}')"
printf '%s' "$out" | jq -e '.hookSpecificOutput' >/dev/null 2>&1 || fail "C: case-insensitive match failed"

# D: `symptoms: []` never matches, even when its description words appear
out="$(run '{"hook_event_name":"PostToolUseFailure","tool_response":"молчаливый дрейф случился","cwd":"/nonexistent"}')"
[ -z "$out" ] || fail "D: empty symptoms list must not match, got: $out"

# E: empty / malformed input -> silent exit 0, never breaks the tool call
[ -z "$(run '{}')" ] || fail "E: empty input produced output"
[ -z "$(printf 'not json' | SERENA_GLOBAL_MEMORIES="$g" bash "$HOOK")" ] || fail "E: malformed input produced output"

# F: a project card outranks nothing but must be reachable via cwd
p="$tmp/proj/.serena/memories"
mkdir -p "$p"
cat > "$p/known-issue.md" <<'EOF'
---
description: "проектная ловушка"
symptoms:
  - "port already allocated"
---
EOF
out="$(run "$(printf '{"hook_event_name":"PostToolUseFailure","tool_response":"Bind for 0.0.0.0:5432 failed: port already allocated","cwd":"%s"}' "$tmp/proj")")"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'mem:known-issue' || fail "F: project card not found"

# G: with NO cwd at all, a global card must still be named `global/…`.
# Regression: an empty cwd made the pattern `/*`, which matched every absolute path and
# stripped the prefix off global cards.
out="$(run '{"hook_event_name":"PostToolUseFailure","tool_response":"integer expression expected"}')"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'mem:global/bash-tool-runs-zsh' \
  || fail "G: global prefix lost when cwd is absent"

# H: UserPromptSubmit — a pasted error surfaces the card, and the event name is echoed back
out="$(run '{"hook_event_name":"UserPromptSubmit","prompt":"падает с (eval):1: no matches found: *.md, почему?"}')"
printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName' | grep -qx 'UserPromptSubmit' \
  || fail "H: wrong hookEventName echoed"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'mem:global/bash-tool-runs-zsh' \
  || fail "H: card not surfaced from a pasted error"

# I: an ordinary prompt with no error text stays silent — a false positive costs more than
# silence, since one irrelevant card measurably degrades the answer.
[ -z "$(run '{"hook_event_name":"UserPromptSubmit","prompt":"давай отрефакторим модуль оплаты"}')" ] \
  || fail "I: ordinary prompt produced noise"

echo "PASS"
