{
  config,
  pkgs,
  lib,
  ...
}: {
  home.file.".local/bin/nvdev" = {
    text = ''
      #!/usr/bin/env bash

      clean=false

      # Parse --clean flag
      if [[ "$1" == "--clean" ]]; then
          clean=true
          shift
      fi

      # Find git root (where init.lua should be)
      git_root=$(git rev-parse --show-toplevel 2>/dev/null)

      # If no git root or no init.lua, check if we're running from anywhere
      if [[ -z "$git_root" ]] || [[ ! -f "$git_root/init.lua" ]]; then
          # Look for nvim configs in standard locations
          configs=()

          # Add main nvim project if it has init.lua
          if [[ -f "$HOME/dev/projects/nvim/init.lua" ]]; then
              configs+=("$HOME/dev/projects/nvim")
          fi

          # Add nvim worktrees that have init.lua
          for dir in "$HOME"/dev/worktrees/nvim/*/; do
              if [[ -f "$dir/init.lua" ]]; then
                  configs+=("$dir")
              fi
          done

          # If no configs found, error out
          if [[ ''${#configs[@]} -eq 0 ]]; then
              echo "❌ No nvim configs found in ~/dev/projects/nvim or ~/dev/worktrees/nvim/*"
              exit 1
          fi

          # If only one config, use it
          if [[ ''${#configs[@]} -eq 1 ]]; then
              git_root="''${configs[0]}"
              echo "🎯 Using only available config: $git_root"
          else
              # Multiple configs - use fzf to select
              echo "🔍 Select nvim config to test:"
              git_root=$(printf '%s\n' "''${configs[@]}" | fzf \
                  --height=40% \
                  --layout=reverse \
                  --prompt="Select config > " \
                  --preview="echo 'Config: {}'; echo '---'; ls -la {} 2>/dev/null | head -20")

              if [[ -z "$git_root" ]]; then
                  echo "❌ No config selected"
                  exit 1
              fi
          fi
      fi

      echo "🧪 Testing nvim config from: $git_root"

      # Check for existing nvdev sessions
      existing_session=$(ls -d /tmp/nvdev-* 2>/dev/null | head -1)

      if [[ "$clean" == true ]]; then
          # Clean up ALL nvdev sessions
          if [[ -n "$existing_session" ]]; then
              rm -rf /tmp/nvdev-*
              echo "✅ Cleaned up all nvdev sessions"
          else
              echo "✅ No sessions to clean"
          fi
          exit 0
      fi

      # If there's an existing session, reuse it
      if [[ -n "$existing_session" ]]; then
          isolated_dir="$existing_session"
          echo "♻️  Reusing existing session: $isolated_dir"

          # Update the symlink in case git root changed
          rm -f "$isolated_dir/config/nvim"
          ln -sf "$git_root" "$isolated_dir/config/nvim"
      else
          # Create new isolated environment
          isolated_dir="/tmp/nvdev-$$"
          echo "🆕 Creating new session: $isolated_dir"
          mkdir -p "$isolated_dir"/{config,data,cache,state}
          ln -sf "$git_root" "$isolated_dir/config/nvim"
      fi

      # set XDG paths and run nvim
      (
        export XDG_CONFIG_HOME="$isolated_dir/config"
        export XDG_DATA_HOME="$isolated_dir/data"
        export XDG_CACHE_HOME="$isolated_dir/cache"
        export XDG_STATE_HOME="$isolated_dir/state"

        echo "📁 Config: $XDG_CONFIG_HOME/nvim -> $git_root"
        nvim "$@"
      )

      echo "💡 Session kept at: $isolated_dir"
      echo "   Run 'nvdev --clean' to remove all sessions"
    '';
    executable = true;
  };
}
