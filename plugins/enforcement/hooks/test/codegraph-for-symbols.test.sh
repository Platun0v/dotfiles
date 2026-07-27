#!/usr/bin/env bash
# Ad-hoc test for codegraph-for-symbols.sh. Exits non-zero on first failure.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/codegraph-for-symbols.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $1"; exit 1; }

indexed="$tmp/proj"; mkdir -p "$indexed/.codegraph" "$indexed/sub/deep"
plain="$tmp/plain";   mkdir -p "$plain"

run() { printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":%s}' "$(jq -Rn --arg c "$1" '$c')" "$(jq -Rn --arg d "$2" '$d')" | bash "$HOOK"; }

# A: bare identifier in an indexed project -> the concrete call, with the term echoed
out="$(run "grep -rn 'CheckAgentReleaseAdmission' ." "$indexed")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 || fail "A: no output"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'codegraph_explore' || fail "A: no call named"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q 'CheckAgentReleaseAdmission' || fail "A: term not echoed"

# B: index found by walking up from a subdirectory
[ -n "$(run "rg DatabaseConfig" "$indexed/sub/deep")" ] || fail "B: index not found from a subdirectory"

# C: no index -> silence
[ -z "$(run "grep -rn 'DatabaseConfig' ." "$plain")" ] || fail "C: fired without an index"

# D: a real pattern is a real text search — leave it alone
[ -z "$(run "grep -rn 'foo|bar' ." "$indexed")" ]        || fail "D: fired on an alternation"
[ -z "$(run "rg '^func .*Handler' ." "$indexed")" ]      || fail "D: fired on a regex"
[ -z "$(run "grep -rn 'fork: NIX-' ." "$indexed")" ]      || fail "D: fired on a marker string"

# E: scans over data, logs and prose stay untouched — that is what grep is for
[ -z "$(run "grep -c Traceback app.log" "$indexed")" ]          || fail "E: fired on a log"
[ -z "$(run "rg description ~/.serena/memories -g '*.md'" "$indexed")" ] || fail "E: fired on markdown"

# F: too short to be worth interrupting for
[ -z "$(run "grep -rn 'err' ." "$indexed")" ] || fail "F: fired on a 3-char term"

# G: already using the index -> stay quiet
[ -z "$(run "codegraph_explore DatabaseConfig" "$indexed")" ] || fail "G: fired while using codegraph"

# H: not a search at all -> instant exit, no output
[ -z "$(run "go build ./..." "$indexed")" ] || fail "H: fired on a non-search command"
[ -z "$(run "cd /tmp && ls" "$indexed")" ]  || fail "H: fired on a plain command"

# I: compound command — the `if` filter cannot catch these, so the script must
out="$(run "cd $indexed && grep -rn 'OperationsConfig' ." "$indexed")"
printf '%s' "$out" | jq -e '.hookSpecificOutput' >/dev/null 2>&1 || fail "I: missed a compound command"

echo "PASS"
