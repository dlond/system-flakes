{ config, pkgs, ... }:
{
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
      DIRENV_LOG_FORMAT = "";
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
    '';
  };
}

