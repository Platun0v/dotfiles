status is-interactive; or exit

# Auto-activate/deactivate a project's `.venv` as you move around the
# filesystem. Generic replacement for the old poetry-specific hook: it matches
# any virtualenv-style `.venv` (uv, python -m venv, poetry-in-project, ...) and
# is not tied to poetry or pyproject.toml.

function __venv_auto_activate_startup --on-event fish_startup
  __venv_auto_activate
end

function __venv_auto_activate --on-variable PWD
  status is-command-substitution; and return

  # Deactivate once we leave the tree of the venv we activated.
  if set -q __venv_dir; and not string match -q "$__venv_dir/*" $PWD/
    functions -q deactivate; and deactivate
    set -e __venv_dir
  end

  # Respect a venv already active (ours, or one activated by hand).
  set -q VIRTUAL_ENV; and return

  # Activate the nearest ancestor `.venv`, walking up from $PWD.
  set -l dir $PWD
  while test -n "$dir"
    if test -e "$dir/.venv/bin/activate.fish"
      source "$dir/.venv/bin/activate.fish"
      set -g __venv_dir $dir
      break
    end
    set dir (string replace -r '/[^/]+$' '' $dir)
  end
end
