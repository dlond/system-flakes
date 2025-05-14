{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../modules/home/base.nix ];

  # Home Manager state version
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # List of packages to install for the user
  home.packages = with pkgs; [
    # CLI Tools / User Apps
    git
    gh
    neovim
    tmux
    # screen # Removed, using tmux instead
    mosh # Added for robust SSH sessions
    fzf # Needed for sf alias and fzf-tab
    zoxide # Needed by fzf-tab style
    bat # Needed for cat alias
    ripgrep
    fd
    oh-my-posh # Needed for prompt
    gnupg
    tree # Re-added for organizational preference
    ruff # For Python formatting/linting

    # Development Languages/Tools (User/Nvim Deps)
    go
    rustup
    nodejs
    nixpkgs-fmt

    # Add xclip conditionally for Linux if 'clip' alias is used there
    # (lib.optional pkgs.stdenv.isLinux xclip)
  ];

  # --- Neovim Configuration ---
  # Links the config from the separate flake input repo
  xdg.configFile."nvim" = {
    source = inputs.nvim-config; # Points to github:dlond/nvim input
    recursive = true;
  };

  # --- Git Configuration ---
  # User-specific settings remain here
  programs.git = {
    enable = true;
    userName = "dlond";
    userEmail = "dlond@me.com";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
      format = "ssh";
      # OS-specific 'signer' is set in mac.nix / linux.nix
    };

    # Common aliases and extraConfig could be moved to common.nix
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

  # --- Tmux Configuration ---
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    # defaultCommand = "${pkgs.zsh}/bin/zsh"; # <-- REMOVED: Invalid direct option
    terminal = "xterm-ghostty";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      catppuccin
      vim-tmux-navigator
      yank
    ];
    baseIndex = 1;
    # paneBaseIndex = 1; # <-- REMOVED: Invalid direct option
    # renumberWindows = true; # <-- REMOVED: Invalid direct option
    mouse = true;
    escapeTime = 10;
    keyMode = "vi";
    extraConfig = ''
      # Set default command for new windows (if shell option isn't enough)
      set-option -g default-command "${pkgs.zsh}/bin/zsh" # Correctly set here

      # Reload config
      unbind r
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf

      # Set terminal overrides for true color support
      set-option -ga terminal-overrides ",xterm-ghostty:Tc"
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      # Enable focus events (good for Neovim)
      set-option -g focus-events on
      
      # Set pane base index
      set -g pane-base-index 1 # Correctly set here
      set-window-option -g pane-base-index 1 # Correctly set here
      
      # Renumber windows
      set-option -g renumber-windows on # Correctly set here

      # Clear virtualenv variable (if needed)
      set-environment -g VIRTUAL_ENV ""

      # Custom Keybindings
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Copy-mode keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Split window bindings (using current path)
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Status bar position
      set-option -g status-position top

      # --- Catppuccin Plugin Settings ---
      set -g @catppuccin_window_right_separator "█ "
      set -g @catppuccin_window_number_position "left"
      set -g @catppuccin_window_middle_separator " | "
      set -g @catppuccin_window_default_fill "none"
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_fill "all"
      set -g @catppuccin_window_current_text "#W"
      set -g @catppuccin_status_modules_right "host session"
      set -g @catppuccin_status_left_separator "█"
      set -g @catppuccin_status_right_separator "█"
      set -g @catppuccin_directory_text "#{pane_current_path}"
    '';
  };

  # --- Zsh Configuration ---
  # Replaces the static .zshrc link
  programs.zsh = {
    enable = true;

    # Common aliases (OS-specific 'clip' is in mac.nix/linux.nix)
    shellAliases = {
      tree = "tree -C"; # Kept alias, tree command comes from this package
      cat = "bat";
      ls = "ls -G";
      ll = "ls -lah";
      vim = "nvim";
      sf = ''fzf -m --preview="bat --color=always {}" --bind "ctrl-w:become(nvim {+}),ctrl-y:execute-silent(echo {} | clip)+abort"'';
      bb = "pushd ~/system-flakes && darwin-rebuild switch --flake .#mbp && popd";
    };

    history = {
      size = 5000;
      save = 5000;
      path = "$HOME/.zsh_history";
      extended = true;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
    };

    # Enable native HM plugins (Correct attribute names)
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    # Initialize completions
    completionInit = "autoload -U compinit && compinit -u";

    # initContent for zinit, keybindings, zstyle, options, OMP
    # Use initContent as requested by user
    initContent = ''
      # Shell Options
      setopt globdots

      # Keybindings
      bindkey -e
      bindkey '^y' autosuggest-accept # For consistency
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # Completion Styling
      if [[ -n "$LS_COLORS" ]]; then
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      fi
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      # Zinit Plugin Manager Setup & Plugin Loading
      ZINIT_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
      if [ ! -d "$ZINIT_HOME" ]; then
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || {
          echo "Error: Failed to clone zinit." >&2
        }
      fi
      if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
        source "''${ZINIT_HOME}/zinit.zsh"
        zinit light Aloxaf/fzf-tab
        zinit snippet OMZP::git
        zinit cdreplay -q
      else
        echo "Error: zinit.zsh not found." >&2
      fi
    ''; # End of initContent
  }; # End of programs.zsh


  # Note: Assumes fzf, zoxide, bat configs are in common.nix
  # If not, their programs.* blocks would need to be here or imported.

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # programs.bat = {
  #   enable = true;
  #   config = {
  #     theme = "Catppuccin Mocha";
  #   };
  # };
  #
  # xdg.configFile."bat/themes" = {
  #   source = ./files/bat/themes;
  #   recursive = true;
  # };

}
