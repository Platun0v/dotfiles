# dotfiles

Based on [this config](https://github.com/neersighted/dotfiles)

## New machine — Claude Code setup

1. Install Homebrew, then: `brew install chezmoi age`
2. Copy your age identity to `~/.config/chezmoi/key.txt` (carried manually; never committed).
3. `chezmoi init --apply platun0v/dotfiles`
   - renders `~/.claude/settings.json` (decrypts `ANTHROPIC_BASE_URL`)
   - installs packages: brew bundle (jq, yq, node, age, …), `uv tool` (serena-agent), `npm -g` (codegraph)
4. `claude login` (proxy auth → macOS Keychain).
5. Launch Claude Code. Marketplaces register and `enabledPlugins` install automatically.

### If plugins don't auto-install (known Claude Code bug #32606)

    claude plugin marketplace add platun0v/dotfiles
    claude plugin install enforcement@platun0v-tools
    claude plugin install mcp-stack@platun0v-tools

Machine-local approvals and project dirs live in `~/.claude/settings.local.json` (not synced).
Change the plugin/marketplace set in `home/dot_claude/settings.json.tmpl`, not via the interactive `/plugin` UI.
