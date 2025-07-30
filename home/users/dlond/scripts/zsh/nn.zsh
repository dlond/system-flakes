#!/usr/bin/env zsh

# nn: darwin-rebuild helper with subcommands and verbose hints
nn() {
  local VERBOSE=false
  local cmd
  local FLAKE_TARGET_REF="HEAD" # Default: use current HEAD of the flake
  local FLAKE_DIR_TO_OPERATE_ON # The directory where git commands/nix builds run
  local DO_GIT_RESET=false # Flag to indicate if a reset operation is needed

  # --- Initial FLAKE_ROOT determination ---
  # This part determines the *default* flake root if not overridden by flags.
  # Use 'cd -' to return to original dir after initial git check
  local original_pwd="$(pwd)"
  if FLAKE_DIR_TO_OPERATE_ON=$(git rev-parse --show-toplevel 2>/dev/null); then
      # If git rev-parse succeeded, it's a git repo.
      :
  else
      # Fallback if not in a Git repo. Assumes current directory is the flake.
      FLAKE_DIR_TO_OPERATE_ON="$original_pwd"
  fi
  # --- End Initial FLAKE_ROOT determination ---


  # Usage text
  read -r -d '' USAGE << 'EOF'
Usage: nn [-v|--verbose] [-R|--reset] [-r <ref>|--ref <ref>] <command> [args]

Commands:
  rebuild      rebuild system
  status       show flake and profile status
  update       pull flake updates & rebuild

Options:
  -v, --verbose  show live‑reload hints after success
  -R, --reset    Target the 'main' flake (~/system-flakes) and reset it to its 'main' branch,
                 removing local changes. This implies -r main for the main flake.
  -r, --ref      Target a specific Git ref (branch/tag/commit) on the *current* flake
                 (or main if -R used). Usage: -r <ref> (e.g., -r my-branch, -r v1.2.3, -r abcdef123)
  -h, --help     show this help message
EOF

  # Global flags
  while [[ "$1" =~ ^- ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=true; shift
        ;;
      -R|--reset)
        FLAKE_DIR_TO_OPERATE_ON="$HOME/system-flakes"
        FLAKE_TARGET_REF="main"
        DO_GIT_RESET=true
        shift
        ;;
      -r|--ref)
        shift # This shift consumes '-r'
        if [[ -z "$1" ]]; then
          echo "nn: -r/--ref requires an argument (Git reference)." >&2
          echo "$USAGE" >&2
          return 1 # Exit immediately if no argument
        fi
        FLAKE_TARGET_REF="$1"
        DO_GIT_RESET=true
        shift # This shift consumes the *argument* to -r
        ;;
      -h|--help)
        echo "$USAGE"; return 0
        ;;
      *)
        # This case is for unknown options, no shift is needed here as it returns immediately.
        echo "nn: unknown option '$1'" >&2
        echo "$USAGE" >&2
        return 1
        ;;
    esac
  done

  # Determine subcommand (default: rebuild)
  cmd=${1:-rebuild}
  # Only shift if an actual command argument was provided (i.e., not a default)
  if [[ -n "$1" ]]; then
    shift
  fi

  # Pre-command checks and Git reset operation
  if $DO_GIT_RESET; then
      echo "→ Preparing flake: '$FLAKE_DIR_TO_OPERATE_ON' for ref: '$FLAKE_TARGET_REF'"
      if [[ ! -d "$FLAKE_DIR_TO_OPERATE_ON" ]]; then
          echo "❌ Error: Flake directory '$FLAKE_DIR_TO_OPERATE_ON' does not exist." >&2
          return 1
      fi
      # Robust Git repository check
      if ! (cd "$FLAKE_DIR_TO_OPERATE_ON" && git rev-parse --is-inside-work-tree &>/dev/null); then
          echo "❌ Error: Cannot reset; '$FLAKE_DIR_TO_OPERATE_ON' is not a Git repository or valid worktree." >&2
          return 1
      fi

      (
        cd "$FLAKE_DIR_TO_OPERATE_ON" || { echo "❌ Cannot change directory to $FLAKE_DIR_TO_OPERATE_ON" >&2; return 1; }
        
        # Fetch to ensure the remote ref exists
        echo "  Fetching remote changes..."
        # Try fetching the specific branch/tag if it's a remote ref
        if ! git fetch origin "$FLAKE_TARGET_REF" 2>/dev/null && ! git rev-parse --verify "$FLAKE_TARGET_REF" &>/dev/null; then
            echo "❌ Error: Git reference '$FLAKE_TARGET_REF' not found in '$FLAKE_DIR_TO_OPERATE_ON'." >&2
            return 1
        fi
        
        echo "  Resetting to '$FLAKE_TARGET_REF'..."
        # Try remote tracking branch first, then local branch/tag/commit
        if ! git reset --hard "origin/$FLAKE_TARGET_REF" 2>/dev/null; then
            if ! git reset --hard "$FLAKE_TARGET_REF"; then
                echo "❌ Failed to reset '$FLAKE_DIR_TO_OPERATE_ON' to '$FLAKE_TARGET_REF'." >&2
                return 1
            fi
        fi
        git clean -df # Remove untracked files and directories
        echo "→ Successfully reset to '$FLAKE_TARGET_REF'."
      ) || return $? # Return if the subshell failed
  fi


  case "$cmd" in
    rebuild)
      echo "→ Running darwin-rebuild switch at '$FLAKE_DIR_TO_OPERATE_ON'."
      sudo darwin-rebuild switch --flake "$FLAKE_DIR_TO_OPERATE_ON" "$@" || {
        echo "❌ rebuild failed (exit $status)" >&2
        return $status
      }
      ;;

    status)
      echo "→ Flake status for: $FLAKE_DIR_TO_OPERATE_ON"
      # Robust Git repository check for status
      if (cd "$FLAKE_DIR_TO_OPERATE_ON" && git rev-parse --is-inside-work-tree &>/dev/null); then
        (cd "$FLAKE_DIR_TO_OPERATE_ON" && \
          echo "  HEAD: $(git rev-parse --short HEAD)" && \
          echo "  Changes:" && git status --short)
      else
        echo "  (Not a Git repository or valid worktree for status)"
      fi
      echo
      echo "→ Profile link:"
      readlink /nix/var/nix/profiles/system-1-link || echo "  (not found)"
      return 0
      ;;

    update)
      echo "→ Updating flake '$FLAKE_DIR_TO_OPERATE_ON'..."
      # Robust Git repository check for update
      if ! (cd "$FLAKE_DIR_TO_OPERATE_ON" && git rev-parse --is-inside-work-tree &>/dev/null); then
          echo "❌ Error: Cannot update; '$FLAKE_DIR_TO_OPERATE_ON' is not a Git repository or valid worktree." >&2
          return 1
      fi

      # Update specifically means 'pull' or 'fetch and rebase'
      # Here, we'll do a simple pull on the current branch
      # Note: This will pull the *current* branch, which might not be 'main'
      if ! (cd "$FLAKE_DIR_TO_OPERATE_ON" && git pull); then
        echo "❌ Flake update failed" >&2
        return 1
      fi
      echo "→ Updated '$FLAKE_DIR_TO_OPERATE_ON' to $(cd "$FLAKE_DIR_TO_OPERATE_ON" && git rev-parse --short HEAD)"
      echo "→ Rebuilding…"
      sudo darwin-rebuild switch --flake "$FLAKE_DIR_TO_OPERATE_ON" "$@"
      ret=$?
      ;;

    *)
      echo "nn: unknown command '$cmd'" >&2
      echo "Available: rebuild, status, update" >&2
      return 1
      ;;
  esac

  # Verbose live‑reload hints
  if $VERBOSE; then
    echo
    echo "✅  '$cmd' succeeded!"
    echo "💡  Live‑reload tips:"
    echo "  • tmux      → Prefix + R (or tmux source-file ~/.tmux.conf)"
    echo "  • Neovim    → nvr --remote-send '<Esc>:so \$MYVIMRC<CR>'"
    echo "  • LSP       → :LspRestart inside Neovim"
    echo "  • Tree‑sitter→ :TSUpdateSync inside Neovim"
    echo "  • Direnv    → direnv reload"
    echo "  • GPG agent → gpgconf --reload gpg-agent"
    echo "  • nix‑daemon → sudo launchctl kickstart -k system/org.nixos.nix-daemon"
    echo "  • Brave     → ⌘+Shift+R"
    echo "  • Firefox   → Ctrl+Shift+R"
    echo "  • Obsidian  → Ctrl+R"
    echo
  fi
}
