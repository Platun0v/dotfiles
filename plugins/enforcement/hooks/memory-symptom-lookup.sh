#!/usr/bin/env bash
# PostToolUseFailure lookup: when a tool call fails, surface any memory card whose
# `symptoms:` frontmatter matches the error text.
#
# This is the retrieval half of the memory system. Cards are read in ~1 session out of
# 72 when the model has to remember they exist; the one card a hook loads is read in 45.
# Binding retrieval to the moment of failure is the whole point.
#
# Bound to PostToolUseFailure, not PostToolUse: it costs nothing on a successful call,
# which matters because hooks are synchronous and paid in every subagent.
#
# Non-blocking: emits additionalContext only, never denies or fails the call.
# Input  (stdin): {"hook_event_name":"PostToolUseFailure","tool_response":…,"cwd":"…"}
# Output (stdout): {"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":"…"}}

set -uo pipefail

MAX_HITS=3
GLOBAL_DIR="${SERENA_GLOBAL_MEMORIES:-$HOME/.serena/memories/global}"

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

# The error text is wherever the harness put it — serialise the whole response plus the
# command that produced it, and match against that. Defensive by design: a schema change
# should make this quieter, never noisier.
err="$(printf '%s' "$input" | jq -r '
  [ (.tool_response // empty | tostring),
    (.tool_input.command // empty),
    (.error // empty | tostring) ] | join("\n")' 2>/dev/null || true)"
[ -n "${err//[[:space:]]/}" ] || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)"

dirs=("$GLOBAL_DIR")
[ -n "$cwd" ] && [ -d "$cwd/.serena/memories" ] && dirs+=("$cwd/.serena/memories")

# Emit "<file>\t<symptom>" for every symptom listed in a card's frontmatter.
# `symptoms: []` is a deliberate declaration that the failure has no error string —
# it carries no list items and so contributes nothing here.
symptom_index() {
  # One awk over every card — a per-file invocation costs more than the scan itself.
  find "${dirs[@]}" -name '*.md' -type f 2>/dev/null -exec awk '
    FNR == 1              { fm = ($0 == "---"); inlist = 0; done = 0; next }
    done || !fm           { next }
    $0 == "---"           { done = 1; next }
    /^symptoms:[[:space:]]*$/ { inlist = 1; next }
    /^[a-zA-Z_]+:/            { inlist = 0 }
    inlist && /^[[:space:]]*-[[:space:]]/ {
      s = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", s)
      gsub(/^["'"'"']|["'"'"']$/, "", s)
      if (length(s) > 3) print FILENAME "\t" s
    }
  ' {} + 2>/dev/null
}

hits=""
count=0
while IFS=$'\t' read -r file symptom; do
  [ -n "$symptom" ] || continue
  if printf '%s' "$err" | grep -qiF -- "$symptom"; then
    # A project card is named bare; a global one keeps its `global/` prefix. Guard on a
    # non-empty cwd — an empty one turns the pattern into `/*`, which matches everything.
    name="global/$(basename "$file" .md)"
    if [ -n "$cwd" ]; then
      case "$file" in "$cwd"/*) name="$(basename "$file" .md)" ;; esac
    fi
    case "$hits" in *"$name"*) continue ;; esac
    desc="$(awk '/^description:/ { sub(/^description:[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; exit }' "$file" 2>/dev/null)"
    hits="${hits}  mem:${name} — ${desc}"$'\n'
    count=$((count + 1))
    [ "$count" -ge "$MAX_HITS" ] && break
  fi
done < <(symptom_index)

[ "$count" -gt 0 ] || exit 0

msg="[memory] Эта ошибка уже описана. Прочитай карточку прежде чем диагностировать заново:"$'\n'"${hits}"
jq -n --arg m "$msg" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUseFailure",
    additionalContext: $m
  }
}'
