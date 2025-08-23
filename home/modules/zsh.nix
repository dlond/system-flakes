{
  config,
  lib,
  pkgs,
  shared,
  ...
}: {
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";

    shellAliases = {
      ls = "eza";
      ll = "eza -l --header --git --icons";
      la = "eza -la --header --git --icons";
      lh = "eza -la --header --git --icons --group-directories-first | grep '^\\.'";
      tree = "eza --tree";
      cat = "bat";
      firefox = "open -a \"Firefox\" --args";
      ndiff = "nvim -d";
      tail = "tail -F";
      clip = shared.clipboardCommand;
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

    sessionVariables = {
      EDITOR = "nvim";
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = ["main"];
    };

    autosuggestion.enable = true;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab.src;
      }
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode.src;
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Disable zoxide doctor warning as a safety net (though proper ordering should fix it)
        export _ZO_DOCTOR=0
      '')
      ''
      # shell options
      setopt globdots
      setopt pushd_silent

      # keybindings
      bindkey '^y' autosuggest-accept
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # completion styling
      if [[ -n "$LS_COLORS" ]]; then
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      fi

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':completion:*:git-checkout:*' sort false

      # safe baseline for ALL fzf-tab popups (visuals only)
      zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --ansi \
        --color=16 \
        --color=fg:#d0d0d0,bg:#1c1c1c,hl:#d75f5f \
        --color=fg+:#ffffff,bg+:#262626,hl+:#ff5f5f \
        --color=info:#af87ff,prompt:#5f87ff,pointer:#ffaf00 \
        --color=marker:#ffff00,spinner:#5f87ff,header:#87af5f \
        --pointer=▶ --marker=✓ --info=inline

      # limp mode for emergencies
      # zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border


      # groups activated
      zstyle ':fzf-tab:*' group
      zstyle ':fzf-tab:*' group-order 'directories' 'files' 'hidden-directories' 'hidden-files'

      # Simple fzf-tab setup
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' prefix ""
      zstyle ':fzf-tab:*' single-group prefix color header

      # Full keybinds to match fzf
      zstyle ':fzf-tab:*' fzf-bindings 'ctrl-n:down' 'ctrl-p:up' 'tab:down' 'shift-tab:toggle+down' 'ctrl-e:execute-silent(echo {+} | ${shared.clipboardCommand})+abort' 'ctrl-w:become(nvim {+})' 'ctrl-y:accept' 'enter:accept'

      # Enable preview for all
      zstyle ':fzf-tab:complete:*' fzf-preview 'if [[ -d $realpath ]]; then eza $realpath; else bat $realpath; fi'

      # Remove problematic preview for now

      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd v edit-command-line

      _update_omp_dirstack_count() {
        export MY_DIRSTACK_COUNT=$#dirstack
      }
      if [[ -z "$precmd_functions" ]]; then
        precmd_functions=()
      fi
      precmd_functions+=(_update_omp_dirstack_count)
      ''
      # Zoxide MUST be initialized at the very end to avoid configuration warnings
      # Using mkOrder 2000 ensures it comes after any mkAfter directives (which are mkOrder 1500)
      # See: https://github.com/nix-community/home-manager/pull/6572
      (lib.mkOrder 2000 ''
        # Initialize zoxide with cd command replacement
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd cd)"
      '')
    ];
  };
}
