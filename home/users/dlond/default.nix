{ pkgs, config, lib, system, ... }:

{
  imports = [
    ../../common.nix
    ./mac.nix # (if pkgs.stdenv.isDarwin then ./mac.nix else ./linux.nix)
  ];

  # Home Manager needs a state version. Put it in the main user entry point.
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # CLI Tools / User Apps
    git
    gh
    neovim
    tmux
    screen
    fzf
    zoxide
    bat
    ripgrep
    fd
    oh-my-posh
    gnupg

    # Development Languages/Tools (User/Nvim Deps)
    go
    rustup
    nodejs
    nixpkgs-fmt
  ];

  # Enable and configure Oh My Posh
  xdg.configFile."omp/my_catppuccin.toml" = {
    source = ../../files/omp/my_catppuccin.toml;
  };

  programs.oh-my-posh = {
    enable = true;
  };

  # Enable Zsh management via Home Manager
  programs.zsh = {
    enable = true;
    # initContent = ''
    #   # Initialize Oh My Posh
    #   if command -v oh-my-posh > /dev/null; then
    #     eval "$(oh-my-posh init zsh --config '${config.xdg.configHome}/omp/my_catppuccin.toml')"
    #   fi
    # '';
  };

  home.file.".zshrc" = {
    source = ../../files/zshrc;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."nvim" = {
    # Source points to the nvim config dir WITHIN your nix config repo
    # Path is relative to this nix file
    source = ../../files/.config/nvim;
    recursive = true;
  };

  programs.git = {
    enable = true;
    userName = "dlond";
    userEmail = "dlond@me.com";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
      format = "ssh";
      # signer = if pkgs.stdenv.isDarwin then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" else "<linux-helper>";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
    };

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      color.ui = true;
      push.default = "current";
    };
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "xterm-ghostty";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      catppuccin
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      set-option -g default-command "${pkgs.zsh}/bin/zsh"
      unbind r
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf

      set-option -ga terminal-overrides ",xterm-ghostty:Tc"
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      set -g mouse on
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      set-option -sg escape-time 10
      set-option -g focus-events on

      set-environment -g VIRTUAL_ENV ""

      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      set-window-option -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      set-option -g status-position top

      # catppuccin settings
      set -g @catppuccin_window_right_separator "█ "
      set -g @catppuccin_window_number_position "left"
      set -g @catppuccin_window_middle_separator " | "

      set -g @catppuccin_window_default_fill "none"
      set -g @catppuccin_window_default_text "#W"

      set -g @catppuccin_window_current_fill "all"
      set -g @catppuccin_window_current_text "#W"

      # set -g @catppuccin_status_modules_right "application session user host date_time"
      # set -g @catppuccin_status_modules_right "directory session"
      set -g @catppuccin_status_modules_right "host session"
      set -g @catppuccin_status_left_separator "█"
      set -g @catppuccin_status_right_separator "█"
      set -g @catppuccin_directory_text "#{pane_current_path}"
    '';
  };
}
