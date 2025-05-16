{ config, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    initExtra = ''
      # fzf-tab (not natively supported yet)
      source ${pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "master";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      }}/fzf-tab.plugin.zsh

      # keybindings
      bindkey -e
      bindkey '^y' autosuggest-accept
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # history
      HISTSIZE=5000
      HISTFILE=$HOME/.zsh_history
      SAVEHIST=$HISTSIZE
      HISTDUP=erase
      setopt appendhistory sharehistory
      setopt hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

      # completion styles
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
      setopt globdots

      # direnv logs
      export DIRENV_LOG_FORMAT=""

      # oh-my-posh (if present)
      if command -v oh-my-posh >/dev/null; then
        eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/my_catppuccin.toml")"
      fi
    '';

    shellAliases = {
      tree = "tree -C";
      cat = "bat";
      ls = "ls -G";
      ll = "ls -lah";
      vim = "nvim";
      sf = ''fzf -m --preview="bat --color=always {}" --bind "ctrl-w:become(nvim {+}),ctrl-y:execute-silent(echo {} | clip)+abort"'';
      clip = if isDarwin then "pbcopy" else "xclip -selection clipboard";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    PATH = lib.mkForce (if isDarwin then
      "$(brew --prefix llvm)/bin:$PATH"
    else
      "$HOME/bin:$PATH");
  };
}

