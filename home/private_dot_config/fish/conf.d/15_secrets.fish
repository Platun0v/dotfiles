# context7 API key: read from chezmoi-managed ~/.claude/.context7_key (0600) and export.
test -r ~/.claude/.context7_key; and set -gx CONTEXT7_API_KEY (cat ~/.claude/.context7_key)
