#!/usr/bin/env bash
set -uo pipefail
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# The operation under test (kept identical to the chezmoi script body):
ensure_patterns() {
  local cfg="$1"
  [ -f "$cfg" ] || return 0   # guard: absent file -> no-op
  yq -i '.ignored_memory_patterns = ((.ignored_memory_patterns // []) + ["_session/.*","_archive/.*","_episodes/.*"] | unique)' "$cfg"
}

# Fixture resembling serena_config.yml: has projects + empty patterns
cfg="$tmp/serena_config.yml"
cat > "$cfg" <<'YAML'
ignored_memory_patterns: []
projects:
  - /Users/me/programming/foo
  - /Users/me/programming/bar
YAML

ensure_patterns "$cfg"
yq -e '.ignored_memory_patterns | contains(["_session/.*"])' "$cfg" >/dev/null || fail "pattern not added"
yq -e '.projects | length == 2' "$cfg" >/dev/null || fail "projects not preserved"

# Idempotent: second run keeps exactly 3 patterns
ensure_patterns "$cfg"
n="$(yq '.ignored_memory_patterns | length' "$cfg")"
[ "$n" = "3" ] || fail "not idempotent (got $n)"

# Guard: absent file is a no-op (no creation)
ensure_patterns "$tmp/nope.yml"
[ ! -f "$tmp/nope.yml" ] || fail "guard failed: created absent file"

echo "PASS"
