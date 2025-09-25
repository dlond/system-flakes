{
  pkgs,
  config,
  shared,
  ...
}: let
  tmuxConf = "${config.xdg.configHome}/tmux/tmux.conf";

  tmuxHelpers = pkgs.writeShellScriptBin "tmux-helpers" ''
        #!/usr/bin/env bash
        set -euo pipefail

        tp_env() {
          PROJECT_DIR=$(pwd);
          if [[ "$PROJECT_DIR" =~ .*/dev/projects/([^/]+) ]]; then
            PROJECT_NAME="''${BASH_REMATCH[1]}"
          elif [[ "$PROJECT_DIR" =~ .*/dev/worktrees/([^/]+)/([^/]+) ]]; then
            PROJECT_NAME="''${BASH_REMATCH[1]}"
          else
            PROJECT_NAME=$(basename "$PROJECT_DIR")
          fi

          SESSION_NAME="$PROJECT_NAME"
          SHARED_NVIM_SESSION="''${PROJECT_NAME}-nvim-shared"
        }

        _default_shared_name() { tp_env; printf '%s\n' "$SHARED_NVIM_SESSION"; }
        _default_base_name() { tp_env; printf '%s\n' "$PROJECT_NAME"; }

        ensure_shared_session() {
          local name="''${1:-$(_default_shared_name)}"
          if ! tmux has-session -t "$name" 2>/dev/null; then
            tmux new-session -d -s "$name" 'nvim .'
            tmux set-option -t "$name" status off
          fi
        }

        attach_shared_or_nvim() {
          local name="''${1:-$(_default_shared_name)}"
          TMUX= tmux attach-session -t "$name" || nvim .
        }

        kill_shared_for() {
          local base="''${1:-$(_default_base_name)}"
          tmux kill-session -t "''${base}-nvim-shared" 2>/dev/null || true
        }

        tp_load() {
          local template="$1"  # full.json or half.json
          tp_env
          local tpl_path="${config.xdg.configHome}/tmuxp/''${template}"
          local target="./.tmuxp.''${PROJECT_NAME}.''${template}"
          sed "s/__SESSION_NAME__/''${SESSION_NAME}/g" "$tpl_path" > "$target"
          tmuxp load "$target"
        }

        usage() {
          cat <<USAGE
    Usage: tmux-helpers <command> [args ...]

    Commands:
        tp_env                        Set environment variables for tmux session names
        tp_load <template>            Load a tmuxp template (full.json or half.json)
        ensure_shared_session <name>  Ensure a shared nvim tmux session exists
        attach_shared_or_nvim <name>  Attach to shared nvim session or open nvim
        kill_shared_for <base>        Kill the shared nvim session for a base name
    USAGE
        }

        cmd="''${1:-}"; shift || true
        case "$cmd" in
          tp-env) tp_env ;;
          tp-load) tp_load "$@" ;;
          ensure-shared-session) ensure_shared_session "$@" ;;
          attach-shared-or-nvim) attach_shared_or_nvim "$@" ;;
          kill-shared-for) kill_shared_for "$@" ;;
          ""|help|-h|--help) usage ;;
          *) echo "Unknown command: $cmd"; usage; exit 1 ;;
        esac
  '';
in {
  # tmuxp templates
  xdg.configFile."tmuxp/full.json".text = ''
    {
      "session_name": "__SESSION_NAME__",
      "tmux_options": "-f ${tmuxConf}",
      "windows": [
        {
          "window_name": "editor",
          "layout": "0171,215x60,0,0[215x44,0,0{139x44,0,0,0,75x44,140,0,2},215x15,0,45,1]",
          "panes": [
            {
              "shell_command_before": ["tmux-helpers ensure-shared-session"],
              "shell_command": ["tmux-helpers attach-shared-or-nvim"]
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
              "shell_command_before": ["tmux-helpers ensure-shared-session"],
              "shell_command": ["tmux-helpers attach-shared-or-nvim"]
            },
            { "shell_command": [] }
          ]
        }
      ]
    }
  '';

  xdg.configFile."tmuxp/half.json".text = ''
    {
      "session_name": "__SESSION_NAME__",
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
  '';

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;
    baseIndex = 1;

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

          set -g status-position top
        '';
      }
    ];

    extraConfig = ''
      set -g default-command "${pkgs.zsh}/bin/zsh -l"
      set -g assume-paste-time 1
      set -g focus-events on
      set -g renumber-windows on
      setw -g aggressive-resize on
      setw -g monitor-activity off

      set -gq allow-passthrough on
      set -g visual-activity off

      bind r source-file ${tmuxConf} \; display-message "Reloaded"

      # Copy-mode bindings (vi-style)
      bind -T copy-mode-vi 'v' send-keys -X begin-selection
      bind -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "${shared.clipboardCommand}"
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${shared.clipboardCommand}"

      # Splits
      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"

      # Navigate panes with Vim keys
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # _E_ven splits
      bind e select-layout even-horizontal
      bind E select-layout even-vertical
      bind t select-layout tiled

      # Switch sessions with fzf (if fzf is installed)
      bind S run-shell "tmux new-session -A -s \"$(tmux list-sessions -F '#{session_name}' | ${pkgs.fzf}/bin/fzf --query=\"$(tmux display-message -p '#{session_name}')\" --exit-0)\""


      # Reload the XDG config quietly
      set-hook -g client-attached 'if-shell "[ -f ${config.xdg.configHome}/tmux/tmux.conf ]" "source-file ${config.xdg.configHome}/tmux/tmux.conf"'

      # Auto-cleanup orphaned shared sessions
      set-hook -g session-closed 'run-shell "case \"#{hook_session}\" in *-nvim-shared) ;; *) tmux kill-session -t \"#{hook_session}-nvim-shared\" 2>/dev/null || true ;; esac"'
    '';
  };

  home.shellAliases = {
    tpfull = "tmux-helpers tp-load full.json";
    tphalf = "tmux-helpers tp-load half.json";
    tmux = "${pkgs.tmux}/bin/tmux -f ${tmuxConf}";
  };

  home.packages = [tmuxHelpers];
}
