#!/usr/bin/env zsh

# nn: darwin-rebuild helper with subcommands and verbose hints
nn() {
  local VERBOSE=false
  local cmd
  local USAGE
  local FLAKE_ROOT=$(git rev-parse --show-toplevel)

  # Usage text
  read -r -d '' USAGE << 'EOF'
Usage: nn [-v|--verbose] [-m|--main] <command> [args]

Commands:
  rebuild       rebuild system
  status        show flake and profile status
  update        pull flake updates & rebuild

Options:
  -v, --verbose  show live‑reload hints after success
  -m, --main     build the main branch
  -h, --help     show this help message
EOF

  # Global flags
  while [[ "$1" =~ ^- ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=true; shift
        ;;
      -m|--main)
        FLAKE_ROOT=~/system-flakes; shift
        ;;
      -h|--help)
        echo "$USAGE"; return 0
        ;;
      *)
        echo "nn: unknown option '$1'" >&2
        echo "$USAGE" >&2
        return 1
        ;;
    esac
  done

  # Determine subcommand (default: rebuild)
  cmd=${1:-rebuild}
  shift

  case "$cmd" in
    rebuild)
      echo "→ Running darwin-rebuild switch…"
      sudo darwin-rebuild switch --flake "$FLAKE_ROOT" "$@"
      status=$?
      ;;

    status)
      echo "→ Flake status:"
      (cd ~/system-flakes && \
        echo "  HEAD: $(git rev-parse --short HEAD)" && \
        echo "  Changes:" && git status --short)
      echo
      echo "→ Profile link:"
      readlink /nix/var/nix/profiles/system-1-link || echo "  (not found)"
      return 0
      ;;

    update)
      echo "→ Updating flake…"
      if cd ~/system-flakes && git pull; then
        echo "→ Updated to $(git rev-parse --short HEAD)"
        echo "→ Rebuilding…"
        sudo darwin-rebuild switch --flake "$FLAKE_ROOT" "$@"
        status=$?
      else
        echo "❌ Flake update failed" >&2
        return 1
      fi
      ;;

    *)
      echo "nn: unknown command '$cmd'" >&2
      echo "Available: rebuild, status, update" >&2
      return 1
      ;;
  esac

  # Handle failure
  if (( status != 0 )); then
    echo "❌ $cmd failed (exit $status)" >&2
    return $status
  fi

  # Verbose live‑reload hints
  if $VERBOSE; then
    echo
    echo "✅  '$cmd' succeeded!"
    echo "💡  Live‑reload tips:"
    echo "   • tmux       → Prefix + R (or tmux source-file ~/.tmux.conf)"
    echo "   • Neovim     → nvr --remote-send '<Esc>:so \$MYVIMRC<CR>'"
    echo "   • LSP        → :LspRestart inside Neovim"
    echo "   • Tree‑sitter→ :TSUpdateSync inside Neovim"
    echo "   • Direnv     → direnv reload"
    echo "   • GPG agent  → gpgconf --reload gpg-agent"
    echo "   • nix‑daemon → sudo launchctl kickstart -k system/org.nixos.nix-daemon"
    echo "   • Brave      → ⌘+Shift+R"
    echo "   • Firefox    → Ctrl+Shift+R"
    echo "   • Obsidian   → Ctrl+R"
    echo
  fi
}
