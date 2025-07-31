{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file.".local/bin/nish" = {
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      FLAKE_ROOT="$(git rev-parse --show-toplevel)"

      system_build() {
        nix build "$FLAKE_ROOT#darwinConfigurations.$(hostname -s).system"
      }

      system_switch() {
        sudo darwin-rebuild switch --flake "$FLAKE_ROOT"
      }

      hm_switch() {
        home-manager switch --flake "$FLAKE_ROOT"
      }

      status() {
        nix flake check "$FLAKE_ROOT"
        echo "→ Git HEAD: $(git rev-parse --short HEAD)"
        echo "→ Git status:"
        git status --short
        echo "→ Current profile link:"
        readlink /nix/var/nix/profiles/system-1-link || echo "(profile not found)"
      }

      update() {
        echo "→ Updating flake at $FLAKE_ROOT"
        git pull
        system_switch
      }

      reset_flake() {
        local ref="\$\{1:-main\}"
        echo "→ Resetting flake at $FLAKE_ROOT to ref: $ref"
        git fetch origin "$ref"
        git reset --hard "origin/$ref"
        git clean -df
      }

      freeze_tmux() {
        echo "📦 Freezing current tmux session state with tmuxp..."
        if command -v tmuxp &>/dev/null && pgrep tmux &>/dev/null; then
          tmuxp freeze > "$HOME/.tmuxp/last-session.yaml"
          echo "✔️ tmux session frozen to ~/.tmuxp/last-session.yaml"
        else
          echo "⚠️ tmux not running or tmuxp not installed. Skipping freeze."
        fi
      }

      show_usage() {
        echo "nish - Nix system management helper"
        echo
        echo "Usage: nish [OPTIONS] COMMAND"
        echo
        echo "Commands:"
        echo "  build       Build system configuration without switching"
        echo "  switch      Apply system configuration changes (requires sudo)"
        echo "  hm          Switch Home Manager configuration only"
        echo "  status      Show flake check, git status, and current profile"
        echo "  update      Pull latest changes and rebuild system"
        echo "  reset [REF] Reset flake to git reference (default: main)"
        echo "  freeze      Save current tmux session layout"
        echo
        echo "Options:"
        echo "  -v, --verbose   Show post-command tips"
        echo "  -h, --help      Show this help message"
        echo
        echo "Examples:"
        echo "  nish switch -v          # Apply changes with verbose tips"
        echo "  nish reset origin/dev   # Reset to development branch"
        echo "  nish status             # Check current system state"
      }

      verbose_tips() {
        echo "✅ Command succeeded!"
        echo "💡 Live‑reload tips:"
        echo "  • tmux → Prefix + R (reload ~/.tmux.conf)"
        echo "  • Neovim → :so \\$MYVIMRC"
        echo "  • LSP → :LspRestart (Neovim)"
        echo "  • Tree‑sitter → :TSUpdateSync (Neovim)"
        echo "  • Direnv → direnv reload"
        echo "  • GPG agent → gpgconf --reload gpg-agent"
        echo "  • nix‑daemon → sudo launchctl kickstart -k system/org.nixos.nix-daemon"
        echo "  • tmuxp restore → tmuxp load ~/.tmuxp/last-session.yaml"
      }

      # Handle no arguments or help flags
      if [[ "$#" -eq 0 ]]; then
        show_usage
        exit 0
      fi

      do_verbose=false
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          -h|--help) show_usage; exit 0 ;;
          -v|--verbose) do_verbose=true; shift ;;
          build) system_build; shift ;;
          switch) system_switch; shift ;;
          hm) hm_switch; shift ;;
          status) status; shift ;;
          update) update; shift ;;
          reset) shift; reset_flake "$@"; exit $? ;;
          freeze) freeze_tmux; shift ;;
          *) echo "Error: Unknown command '$1'"; echo; show_usage; exit 1 ;;
        esac
      done

      $do_verbose && verbose_tips
    '';
    executable = true;
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
