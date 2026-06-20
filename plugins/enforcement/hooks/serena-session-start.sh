#!/usr/bin/env bash
# SessionStart(startup|resume): if the project has a saved Serena session-state
# file, inject it as context and nudge the model to resume via serena-bootstrap.
#
# Non-blocking, context-only. Silent when there is no state file.
# Input  (stdin): {"hook_event_name":"SessionStart","source":"...","cwd":"..."}
# Output (stdout): {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}

set -euo pipefail

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)"
[ -n "$cwd" ] || exit 0

state="$cwd/.serena/memories/_session/current.md"
[ -f "$state" ] || exit 0

body="$(cat "$state")"

ctx="[serena-bootstrap] Saved Serena session state for this project — resume from here. Invoke the \`serena-bootstrap\` skill to activate the project, load the relevant memories, and confirm the next step before continuing.

----- .serena/memories/_session/current.md -----
$body"

jq -n --arg ctx "$ctx" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
exit 0
