{
  config,
  lib,
  pkgs,
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
      sf = ''
        fzf -m --preview="bat --color=always {}" \
          --bind "ctrl-w:become(nvim {+}),ctrl-y:execute-silent(echo {} | pbcopy)+abort"
      '';
      firefox = ''open -a "Firefox" --args'';
      ndiff = "nvim -d";
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

    initContent = ''
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
      zstyle ':fzf-tab:*' fzf-bindings 'ctrl-n:down,ctrl-p:up,ctrl-y:accept,tab:ignore,enter:ignore';
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color $realpath'

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
    '';
  };
}
