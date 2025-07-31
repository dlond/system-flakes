{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 100000;
    prefix = "C-a";
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
          set -g @catppuccin_flavour 'mocha' # latte, frappe, macchiato, mocha
          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator ""
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_middle_separator "█"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_status_modules_right "directory host_ip application session"
          set -g @catppuccin_status_modules_left "session"
          set -g @catppuccin_pane_copy_mode_text "  COPY "

          # For example, to ensure the status bar updates frequently:
          set -g status-interval 1
          set -g status-justify left
        '';
      }
    ];

    # --- ALL raw tmux.conf commands go into ONE extraConfig string ---
    extraConfig =
      # ensure default shell is Zsh and spawn it as a login shell
      ''
        set -g default-shell ${pkgs.zsh}/bin/zsh
        set -g default-command "${pkgs.zsh}/bin/zsh -l"
      ''
      # Make sure to use lib.optionalString to convert the conditional to a string
      + lib.optionalString (config.programs.tmux.prefix == "C-a") ''
        unbind C-b
      ''
      + lib.optionalString (config.programs.tmux.keyMode == "vi") ''
        bind -T copy-mode-vi 'v' send-keys -X begin-selection
        # For macOS
        bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        # For Linux (uncomment if you're also using Linux with xclip)
        # bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -i -selection clipboard"
        bind -T copy-mode-vi MouseDragEnd1Pane copy-selection
      ''
      + ''
        # Options that are not directly exposed by Home Manager's programs.tmux module
        # but are common tmux settings.

        setw -g pane-base-index 1
        set -g renumber-windows on

        # Automatic renaming
        # setw -g automatic-rename off # disable automatic rename
        # set -g automatic-rename-forced off # for forced automatic rename

        # Bindings
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "~/.config/tmux/tmux.conf reloaded!"

        # Use 'v' and 's' for vertical and horizontal splits
        bind v split-window -h -c "#{pane_current_path}"
        bind s split-window -v -c "#{pane_current_path}"

        # Navigate panes with Vim keys
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Resize panes with Shift + Vim keys
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Sync panes
        bind e set-window-option synchronize-panes

        # Switch sessions with fzf (if fzf is installed)
        bind S run-shell "tmux new-session -A -s \"$(tmux list-sessions -F '#{session_name}' | ${pkgs.fzf}/bin/fzf --query=\"$(tmux display-message -p '#{session_name}')\" --exit-0)\""
      '';
  };
}
