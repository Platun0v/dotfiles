#!/usr/bin/env bash
# Ad-hoc test for serena-session-start.sh. Exits non-zero on first failure.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/serena-session-start.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $1"; exit 1; }

# Case A: state file present -> additionalContext contains state body + skill name
mkdir -p "$tmp/.serena/memories/_session"
printf '# Session state\n## Next step\n- do the thing\n' > "$tmp/.serena/memories/_session/current.md"
out="$(printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$tmp" | bash "$HOOK")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1 || fail "A: no additionalContext"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "do the thing" || fail "A: state body missing"
printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | grep -q "serena-bootstrap" || fail "A: skill directive missing"

# Case B: no state file -> empty stdout (no noise)
out2="$(printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$tmp/empty" | bash "$HOOK")"
[ -z "$out2" ] || fail "B: expected empty stdout, got: $out2"

echo "PASS"
