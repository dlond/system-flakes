{
  config,
  pkgs,
  lib,
  inputs,
  username,
  nvim-config,
  catppuccin-bat,
  ...
}: {
  home.username = "${username}";
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    oh-my-posh
  ];

  imports = [
    ./modules/networking/mullvad-vpn.nix
  ];

  home.modules.networking.mullvadVpn.enable = true;

  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    shellAliases = {
      nn = "sudo darwin-rebuild switch --flake ~/system-flakes";
      hh = "home-manager switch --flake ~/system-flakes#dlond@mbp";
      clip = "pbcopy";
      cat = "bat";
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
      # FZF_DEFAULT_OPTS = "\
      #   --prompt=' '\
      #   --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4";
      # FZF_COMPLETION_OPTS = "\
      #   --prompt=' '\
      #   --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4";
    };
    syntaxHighlighting.enable = true;
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
      # Shell Options
      setopt globdots
      setopt PUSHD_SILENT

      # Keybindings
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

      _update_omp_dirstack_count() {
        export MY_DIRSTACK_COUNT=$#dirstack
      }
      if [[ -z "$precmd_functions" ]]; then
        precmd_functions=()
      fi
      precmd_functions+=(_update_omp_dirstack_count)
    '';
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
      window-inherit-working-directory = false

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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--prompt=' '"
      "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4"
      "--bind=ctrl-y:accept"
    ];
    # completionOptions = [
    #   "--prompt=' '"
    #   "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4"
    #   "--bind=ctrl-y:accept"
    # ];
    # historyOptions = [
    #   "--prompt=' '"
    #   "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4"
    #   "--bind=ctrl-y:accept"
    # ];
    # fileOptions = [
    #   "--prompt=' '"
    #   "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4"
    #   "--bind=ctrl-y:accept"
    # ];
    # dirOptions = [
    #   "--prompt=' '"
    #   "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8,fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC,marker:#B4BEFE,fg+:#CDD6F4,prompt:#ACB0BE,hl+:#F38BA8,selected-bg:#45475A,border:#313244,label:#CDD6F4"
    #   "--bind=ctrl-y:accept"
    # ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    silent = true;
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
}
