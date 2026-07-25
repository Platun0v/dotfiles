#!/usr/bin/env bash
set -uo pipefail
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo_root/home/.chezmoiscripts/run_onchange_after_serena-ignored-memory-patterns.sh.tmpl"
[ -f "$script" ] || fail "script not found at $script"

# The file is a chezmoi template by name only: it contains no template actions, so the
# test executes the real artifact rather than a copy of its body. If that ever changes,
# fail loudly instead of silently testing an unrendered script.
grep -q '{{' "$script" && fail "script gained chezmoi template actions; render it before testing"

# The operation under test: the real script, pointed at a throwaway HOME.
ensure_patterns() { HOME="$1" bash "$script" >/dev/null; }

# Fixture resembling serena_config.yml: has projects + a pre-existing custom pattern, so
# the merge (union, not replace) is exercised the same way real configs are — a fresh
# machine never actually has an empty ignored_memory_patterns.
home="$tmp/home"; mkdir -p "$home/.serena"
cfg="$home/.serena/serena_config.yml"
cat > "$cfg" <<'YAML'
ignored_memory_patterns:
  - my/custom/.*
projects:
  - /Users/me/programming/foo
  - /Users/me/programming/bar
YAML

ensure_patterns "$home" || fail "script exited non-zero on happy path"
yq -e '.ignored_memory_patterns | contains(["_session/.*", "_archive/.*", "_episodes/.*", ".*[.]sync-conflict-.*"])' "$cfg" >/dev/null \
  || fail "not all four patterns were added"
yq -e '.ignored_memory_patterns | contains(["my/custom/.*"])' "$cfg" >/dev/null \
  || fail "pre-existing custom pattern was dropped by the merge"
yq -e '.projects | length == 2' "$cfg" >/dev/null || fail "projects not preserved"

# Idempotent: second run keeps exactly 5 patterns (4 added + 1 pre-existing)
ensure_patterns "$home" || fail "script exited non-zero on second (idempotent) run"
n="$(yq '.ignored_memory_patterns | length' "$cfg")"
[ "$n" = "5" ] || fail "not idempotent (got $n)"

# Regex semantics: Serena matches memory names with re.fullmatch, so anchor the check.
# A real Syncthing conflict name must match...
echo 'global/doc-writing-style.sync-conflict-20260726-120000-K3JQ2LM' \
  | grep -qE '^.*[.]sync-conflict-.*$' || fail "pattern does not fullmatch a conflict name"
# ...and an ordinary memory name must not.
echo 'global/doc-writing-style' \
  | grep -qE '^.*[.]sync-conflict-.*$' && fail "pattern over-matches an ordinary name"

# Guard: absent file is a no-op (no creation) and must still exit successfully — a fresh
# machine where Serena hasn't run yet must not fail `chezmoi apply`.
empty="$tmp/empty"; mkdir -p "$empty"
ensure_patterns "$empty" || fail "guard path must exit 0 when config is absent"
[ ! -f "$empty/.serena/serena_config.yml" ] || fail "guard failed: created absent file"

echo "PASS"
