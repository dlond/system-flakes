{
  config,
  pkgs,
  lib,
  sops-nix,
  nvim-config,
  catppuccin-bat,
  ...
}: let
  my_bindings = "ctrl-n:down,ctrl-p:up,ctrl-y:accept";
in {
  home.stateVersion = "25.11";
  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";

  imports = [
    sops-nix.homeManagerModules.sops
  ];

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    oh-my-posh
  ];

  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    shellAliases = {
      nn = "sudo darwin-rebuild switch --flake ~/system-flakes";
      hh = "home-manager switch --flake ~/system-flakes#dlond@mbp";
      cat = "bat";
      ll = "ls -lah";
      sf = ''
        fzf -m --preview="bat --color=always {}"
        --bind "ctrl-w:become(nvim {+}),ctrl-y:execute-silent(echo {} | pbcopy)+abort
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
      zstyle ':fzf-tab:*' fzf-bindings 'ctrl-p:up,ctrl-n:down,ctrl-y:accept'
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color $realpath'

      _update_omp_dirstack_count() {
        export MY_DIRSTACK_COUNT=$#dirstack
      }
      if [[ -z "$precmd_functions" ]]; then
        precmd_functions=()
      fi
      precmd_functions+=(_update_omp_dirstack_count)
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--bind=${my_bindings}"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./themes/dlond.omp.json));
  };

  programs.bat = {
    enable = true;
    themes = {
      catppuccin = {
        src = "${catppuccin-bat}/themes";
        file = "Catppuccin Mocha.tmTheme";
      };
    };
    config = {
      theme = "catppuccin";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    silent = true;
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

  xdg.configFile."ghostty/config" = {
    text = ''
      font-family = "JetBrains Mono Nerd Font"
      font-size = 13
      theme = dlond.ghostty

      working-directory = "${config.home.homeDirectory}"

      keybind = global:option+space=toggle_quick_terminal
    '';
  };
  xdg.configFile."ghostty/themes/dlond.ghostty" = {
    source = ./themes/dlond.ghostty;
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

  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
}
