#!/usr/bin/env bash
# PreToolUse(Bash): when a command greps for a plain identifier inside a project that has a
# codegraph index, name the one call that answers it.
#
# Why this exists in a specific form. The harness already emits a generic "use symbolic
# tools" nudge — it appears in 349 transcript files and is ignored, so repeating it would be
# a no-op. And availability is not the gap either: `.codegraph` is present in all six real
# projects. What is missing is the concrete call, so that is all this supplies.
#
# Deliberately narrow. A regex, a metacharacter, a log or a markdown scan is a legitimate
# text search that CLAUDE.md explicitly reserves for grep; those stay untouched. Only a bare
# identifier — the case an index answers better — is worth a word.
#
# Non-blocking: emits additionalContext only. Never denies the call.
# Input  (stdin): {"tool_name":"Bash","tool_input":{"command":"…"},"cwd":"…"}
# Output (stdout): {"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"…"}}

set -uo pipefail

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

# Fast exit: the overwhelming majority of Bash calls are not searches.
printf '%s' "$cmd" | grep -Eq '(^|[|;& ])(grep|rg|ag)([[:space:]]|$)' || exit 0

# Already reaching for the index, or asking about the index itself — stay quiet.
printf '%s' "$cmd" | grep -q 'codegraph' && exit 0

# A text scan over data, logs or prose is the case grep is for. Leave it alone.
printf '%s' "$cmd" | grep -Eq '\.(jsonl?|log|md|txt|ya?ml|toml|csv|xml)\b' && exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)"
[ -n "$cwd" ] || exit 0

# Walk up for an index; a subdirectory cwd is normal.
root="$cwd"
while [ "$root" != "/" ] && [ ! -d "$root/.codegraph" ]; do root="$(dirname "$root")"; done
[ -d "$root/.codegraph" ] || exit 0

# The search term: first quoted argument, else the first non-flag word after the tool.
pat="$(printf '%s' "$cmd" | sed -n "s/.*\(grep\|rg\|ag\)[^'\"]*['\"]\([^'\"]*\)['\"].*/\2/p" | head -1)"
[ -n "$pat" ] || pat="$(printf '%s' "$cmd" \
  | awk '{ for (i = 1; i < NF; i++) if ($i ~ /(grep|rg|ag)$/) { for (j = i + 1; j <= NF; j++) if ($j !~ /^-/) { print $j; exit } } }')"

# A bare identifier is the only shape an index answers better. Anything with a metacharacter
# is a real pattern; anything short is too ambiguous to be worth interrupting for.
printf '%s' "$pat" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]{3,}$' || exit 0

msg="[codegraph] «${pat}» — идентификатор, и у ${root##*/} есть индекс. Один вызов вместо grep+Read:
  codegraph_explore(query: \"${pat}\", projectPath: \"${root}\")
Он вернёт исходник символа и путь вызовов между найденным. Текстовый скан по строкам, комментариям и конфигам — по-прежнему grep."

jq -n --arg m "$msg" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $m
  }
}'
