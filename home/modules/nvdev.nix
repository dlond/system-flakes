{
  config,
  pkgs,
  lib,
  ...
}: {
  home.file.".local/bin/nvdev" = {
    text = ''
      #!/bin/bash
      # Launch Neovim with completely isolated config
      export NVIM_APPNAME="nvim-custom"
      export XDG_DATA_HOME="$HOME/dev/projects/nvim/.local/share"
      export XDG_CACHE_HOME="$HOME/dev/projects/nvim/.cache"
      export XDG_STATE_HOME="$HOME/dev/projects/nvim/.local/state"

      # Create directories if they don't exist
      mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

      # Setup logging
      LOGFILE="$HOME/dev/projects/nvim/.local/state/nvim-launch.log"
      mkdir -p "$(dirname "$LOGFILE")"

      echo "=== Neovim Launch $(date) ===" >> "$LOGFILE"
      echo "NVIM_APPNAME: $NVIM_APPNAME" >> "$LOGFILE"
      echo "XDG_DATA_HOME: $XDG_DATA_HOME" >> "$LOGFILE"
      echo "XDG_CACHE_HOME: $XDG_CACHE_HOME" >> "$LOGFILE"
      echo "XDG_STATE_HOME: $XDG_STATE_HOME" >> "$LOGFILE"
      echo "Args: $*" >> "$LOGFILE"
      echo "---" >> "$LOGFILE"

      # Enable verbose Neovim logging
      export NVIM_LOG_FILE="$HOME/dev/projects/nvim/.local/state/nvim.log"

      # Launch with isolated config and proper runtime path
      echo "Launching nvim..." >> "$LOGFILE"
      nvim --cmd "set rtp^=$HOME/dev/projects/nvim" --cmd "set packpath^=$HOME/dev/projects/nvim" -u ~/dev/projects/nvim/init.lua "$@" 2>>"$LOGFILE"

      echo "Neovim exited with code: $?" >> "$LOGFILE"
      echo "" >> "$LOGFILE"
    '';
    executable = true;
  };
}