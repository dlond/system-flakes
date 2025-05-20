{
  pkgs,
  lib,
  nvim-config,
  ...
}: {
  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    oh-my-posh
  ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      "nix-up" = "pushd ~/system-flakes && sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName) && popd";
      clip = "pbcopy";
      tree = "tree -C";
      cat = "bat";
      ls = "ls -G";
      ll = "ls -lah";
      sf = ''fzf -m --preview="bat --color=always {}" --bind "ctrl-w:become(nvim {+}),ctrl-y:execute-silent(echo {} | clip)+abort"'';
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
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    completionInit = "autoload -U compinit && compinit -u";

    initContent = ''
      # Shell Options
      setopt globdots
      setopt PUSHD_SILENT

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

      _update_omp_dirstack_count() {
        export MY_DIRSTACK_COUNT=$#dirstack
      }
      if [[ -z "$precmd_functions" ]]; then
        precmd_functions=()
      fi
      precmd_functions+=(_update_omp_dirstack_count)

      # Prompt
      eval "$(oh-my-posh init zsh --config ~/.poshthemes/dlond.omp.toml)"
    '';
  };
  home.file."/.poshthemes/dlond.omp.toml".source = ../themes/dlond.omp.toml;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    withPython3 = true;
    withNodeJs = true;
  };
  home.file = {
    ".config/nvim/init.lua" = {
      source = nvim-config + "/init.lua";
    };
    ".config/nvim/lua" = {
      source = nvim-config + "/lua";
      recursive = true;
    };
    ".config/nvim/.stylua.toml" = {
      source = nvim-config + "/.stylua.toml";
    };
    ".config/nvim/doc" = {
      source = nvim-config + "/doc";
      recursive = true;
    };
    ".config/nvim/LICENSE.md" = {
      source = nvim-config + "/LICENSE.md";
    };
    ".config/nvim/README.md" = {
      source = nvim-config + "/README.md";
    };
  };

  programs.git = {
    enable = true;

    userName = "dlond";
    userEmail = "dlond@me.com";

    signing =
      {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
        format = "ssh";
      }
      // lib.mkIf pkgs.stdenv.isDarwin {
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      }
      // lib.mkIf pkgs.stdenv.isLinux {
        signer = "";
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

  # You can add other programs here
}
