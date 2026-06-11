#!/usr/bin/env bash
# PreToolUse(Bash) reminder: nudge toward the data-tools skill (jq/yq/dasel/mlr)
# when a Bash command reaches for grep/sed/awk or inline interpreters on
# structured data (JSON/JSONL/YAML/TOML/XML/CSV).
#
# Non-blocking: emits additionalContext only. Never denies the call.
# Input  (stdin): {"tool_name":"Bash","tool_input":{"command":"..."}}
# Output (stdout): {"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"..."}}

set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"

# Nothing to inspect.
[ -n "$cmd" ] || exit 0

# Already using a structured-data tool? Then the rule is being followed — stay quiet.
if printf '%s' "$cmd" | grep -Eq '\b(jq|yq|dasel|mlr|qsv)\b'; then
  exit 0
fi

# Does it reference a structured-data file/extension?
has_structured_target=false
if printf '%s' "$cmd" | grep -Eiq '\.(json|jsonl|ndjson|ya?ml|toml|xml|csv|tsv)\b'; then
  has_structured_target=true
fi

# Does it use a text tool / inline interpreter that breaks on structure?
uses_text_tool=false
if printf '%s' "$cmd" | grep -Eq '\b(grep|egrep|fgrep|sed|awk)\b'; then
  uses_text_tool=true
fi
if printf '%s' "$cmd" | grep -Eq '\b(python3?|node)\b[[:space:]]+-(c|e)\b'; then
  uses_text_tool=true
fi

if [ "$has_structured_target" = true ] && [ "$uses_text_tool" = true ]; then
  read -r -d '' msg <<'EOF' || true
[data-tools reminder] This Bash command uses grep/sed/awk or an inline interpreter on a structured-data file (JSON/JSONL/YAML/TOML/XML/CSV). The data-tools skill's critical rule: NEVER use grep/sed/awk/python -c/node -e on structured formats — they break on structure. Prefer jq (JSON), yq (YAML/TOML/XML), dasel, mlr/qsv (CSV). If unsure of syntax, invoke the `data-tools:data-tools` skill for cookbooks. Proceed with the text tool only if the target is genuinely unstructured/free-form text.
EOF
  jq -n --arg ctx "$msg" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
  exit 0
fi

exit 0
