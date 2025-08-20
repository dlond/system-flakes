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
      export XDG_DATA_HOME="$PWD/.local/share"
      export XDG_CACHE_HOME="$PWD/.cache"
      export XDG_STATE_HOME="$PWD/.local/state"

      # Create directories if they don't exist
      mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

      # Setup logging
      LOGFILE="$PWD/.local/state/nvim-launch.log"
      mkdir -p "$(dirname "$LOGFILE")"

      echo "=== Neovim Launch $(date) ===" >> "$LOGFILE"
      echo "NVIM_APPNAME: $NVIM_APPNAME" >> "$LOGFILE"
      echo "XDG_DATA_HOME: $XDG_DATA_HOME" >> "$LOGFILE"
      echo "XDG_CACHE_HOME: $XDG_CACHE_HOME" >> "$LOGFILE"
      echo "XDG_STATE_HOME: $XDG_STATE_HOME" >> "$LOGFILE"
      echo "Args: $*" >> "$LOGFILE"
      echo "---" >> "$LOGFILE"

      # Enable verbose Neovim logging
      export NVIM_LOG_FILE="$PWD/.local/state/nvim.log"

      # Launch with isolated config and proper runtime path
      echo "Launching nvim..." >> "$LOGFILE"
      nvim --cmd "set rtp^=$PWD" --cmd "set packpath^=$PWD" -u "$PWD/init.lua" "$@" 2>>"$LOGFILE"

      echo "Neovim exited with code: $?" >> "$LOGFILE"
      echo "" >> "$LOGFILE"
    '';
    executable = true;
  };
}