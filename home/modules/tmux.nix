{
  pkgs,
  config,
  lib,
  ...
}: let
  tmuxConf = "${config.xdg.configHome}/tmux/tmux.conf";

  tmuxHelpers = pkgs.writeShellScriptBin "tmux-helpers" ''
    set -euo pipefail

    # Always use your XDG tmux.conf
    tmx() { command tmux -f "${tmuxConf}" "$@"; }

    # ensure_shared_session NAME
    # - creates NAME if missing, starts with nvim .
    # - hides tmux status bar in that shared session
    ensure_shared_session() {
      local name="$1"
      if ! tmx has-session -t "$name" 2>/dev/null; then
        tmx new-session -d -s "$name" 'nvim .'
        tmx set-option -t "$name" status off
      fi
    }

    # attach_shared_or_nvim NAME
    # - detaches from outer tmux env var to allow attach
    attach_shared_or_nvim() {
      local name="$1"
      TMUX= tmx attach-session -t "$name" || nvim .
    }

    # kill_shared_for BASE
    # - best-effort cleanup of BASE-nvim-shared
    kill_shared_for() {
      local base="$1"
      tmx kill-session -t "''${base}-nvim-shared" 2>/dev/null || true
    }
  '';

  # Small helper to write a tmuxp JSON on the fly
  mkTpScript = name: layout:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      # Figure out project and session names from PWD
      PROJECT_DIR=$(pwd)
      if [[ "$PROJECT_DIR" =~ .*/dev/projects/([^/]+) ]]; then
        PROJECT_NAME="''${BASH_REMATCH[1]}"
      elif [[ "$PROJECT_DIR" =~ .*/dev/worktrees/([^/]+)/([^/]+) ]]; then
        PROJECT_NAME="''${BASH_REMATCH[1]}"
      else
        PROJECT_NAME=$(basename "$PROJECT_DIR")
      fi

      SESSION_NAME="$PROJECT_NAME"
      SHARED_NVIM_SESSION="''${PROJECT_NAME}-nvim-shared"

      cfg="$(mktemp -t tmuxp-"$PROJECT_NAME".XXXX.json)"

      ${
        if layout == "full"
        then ''
              cat >"$cfg" <<JSON
          {
            "session_name": "$SESSION_NAME",
            "tmux_options": "-f ${tmuxConf}",
            "windows": [
              {
                "window_name": "editor",
                "layout": "0171,215x60,0,0[215x44,0,0{139x44,0,0,0,75x44,140,0,2},215x15,0,45,1]",
                "panes": [
                  {
                    "shell_command_before": ["tmux-helpers ensure_shared_session $SHARED_NVIM_SESSION"],
                    "shell_command": ["tmux-helpers attach_shared_or_nvim $SHARED_NVIM_SESSION"]
                  },
                  { "shell_command": ["claude"] },
                  { "shell_command": [] }
                ]
              },
              {
                "window_name": "side-by-side",
                "layout": "e5e0,215x60,0,0{107x60,0,0,3,107x60,108,0,4}",
                "panes": [
                  {
                    "shell_command_before": ["tmux-helpers ensure_shared_session $SHARED_NVIM_SESSION"],
                    "shell_command": ["tmux-helpers attach_shared_or_nvim $SHARED_NVIM_SESSION"]
                  },
                  { "shell_command": [] }
                ]
              }
            ]
          }
          JSON
        ''
        else ''
              cat >"$cfg" <<JSON
          {
            "session_name": "$SESSION_NAME",
            "tmux_options": "-f ${tmuxConf}",
            "windows": [
              {
                "window_name": "editor",
                "layout": "even-vertical",
                "panes": [
                  { "shell_command": ["nvim ."] },
                  { "shell_command": [] }
                ]
              }
            ]
          }
          JSON
        ''
      }

      tmuxp load "$cfg"
    '';
in {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 100000;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;
    baseIndex = 1;

    # Plugins
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      vim-tmux-navigator
      cpu
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour "mocha"

          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator ""
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_middle_separator "█"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_status_modules_right "directory host_ip application session"
          set -g @catppuccin_status_modules_left "session"
          set -g @catppuccin_pane_copy_mode_text "  COPY "
        '';
      }
      # tpm
      # resurrect
      # continuum
      # open
      # battery
      # prefix-highlight
      # themepack
    ];

    extraConfig = ''
      # ---------- sane defaults ----------
      set -g assume-paste-time 1
      set -g focus-events on
      set -g renumber-windows on
      setw -g aggressive-resize on
      setw -g monitor-activity off
      setw -g mode-keys vi

      # Statusline (outer sessions keep it on; shared nvim will disable via helpers)
      # set -g status on
      # set -g status-interval 5
      # set -g status-bg colour234
      # set -g status-fg white

      # Reload the *XDG* config quietly on attach (no ~/.tmux.conf probe)
      set-hook -g client-attached 'if-shell "[ -f ''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf ]" "source-file ''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"'

      # Optional: when a *project* session closes, best-effort kill its shared one
      # (No-op if it doesn't exist; avoids leaving orphaned -nvim-shared sessions)
      set-hook -g session-closed 'run-shell "case \"#{hook_session}\" in *-nvim-shared) ;; *) tmux kill-session -t \"#{hook_session}-nvim-shared\" 2>/dev/null || true ;; esac"'
    '';
  };

  home.packages = [
    tmuxHelpers
    (mkTpScript "tp-full" "full")
    (mkTpScript "tp-half" "half")
  ];
}
