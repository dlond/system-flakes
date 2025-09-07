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

      if [[ -z "$git_root" ]] || [[ ! -f "$git_root/init.lua" ]]; then
          echo "❌ No nvim config found (need init.lua at git root)"
          exit 1
      fi

      echo "🧪 Testing nvim config from: $git_root"

      [[ -d "$isolated_dir" ]] && rm -rf "$isolated_dir"

      # Create isolated environment
      isolated_dir="/tmp/nvdev-$$"
      mkdir -p "$isolated_dir"/{config,data,cache,state}
      ln -sf "$git_root" "$isolated_dir/config/nvim"

      # set XDG paths
      (
        export XDG_CONFIG_HOME="$isolated_dir/config"
        export XDG_DATA_HOME="$isolated_dir/data"
        export XDG_CACHE_HOME="$isolated_dir/cache"
        export XDG_STATE_HOME="$isolated_dir/state"

        echo "📁 Config: $XDG_CONFIG_HOME/nvim -> $git_root"
        nvim "$@"
      )

      sleep 0.5

      # Cleanup
      if [[ "$clean" == true ]] || [[ -z "''${NVDEV_KEEP:-}" ]]; then
        rm -rf "$isolated_dir"
        echo "✅ Cleaned up"
      else
        echo "📌 Kept temp dir: $isolated_dir"
      fi
    '';
    executable = true;
  };
}
