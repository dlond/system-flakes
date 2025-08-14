{
  config,
  pkgs,
  lib,
  sops-nix,
  nvim-config,
  catppuccin-bat,
  ...
}: let
in {
  home.stateVersion = "25.11";
  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";

  imports = [
    sops-nix.homeManagerModules.sops
    ../../modules/fzf.nix
    ../../modules/git.nix
    ../../modules/nish.nix
    ../../modules/tmux.nix
    ../../modules/tmuxp.nix
    ../../modules/zsh.nix
  ];

  home.packages = with pkgs; [
    oh-my-posh
  ];

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

      working-directory = "${config.home.homeDirectory}/dev"
      window-inherit-working-directory = false

      keybind = global:option+space=toggle_quick_terminal
    '';
  };
  xdg.configFile."ghostty/themes/dlond.ghostty" = {
    source = ./themes/dlond.ghostty;
  };

  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
}
