{
  config,
  pkgs,
  lib,
  sops-nix,
  nvim-config,
  catppuccin-bat,
  ...
}: {
  home.stateVersion = "25.05";
  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";

  imports = [
    sops-nix.homeManagerModules.sops
    ../../modules/fzf.nix
    ../../modules/git.nix
    ../../modules/gwt.nix
    ../../modules/claude-monitoring.nix
    ../../modules/nvdev.nix
    ../../modules/tmux.nix
    ../../modules/zsh.nix
    ../../modules/neovim.nix
  ];

  home.packages = with pkgs; [
    oh-my-posh
    zoxide # Add zoxide to packages since we're managing it manually
  ];

  # Zoxide is handled entirely in zsh.nix to control initialization order
  # programs.zoxide = {
  #   enable = true;
  #   enableZshIntegration = false; # We'll manually init at the end of zshrc
  #   options = ["--cmd cd"];
  # };

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

  programs.neovim-cfg = {
    enable = true;
    withCopilot = true;
    withDebugger = true;
  };

  xdg.configFile."ghostty/config" = {
    text = ''
      font-family = "JetBrains Mono Nerd Font"
      font-size = 13
      theme = dlond.ghostty

      working-directory = "${config.home.homeDirectory}/dev"
      window-inherit-working-directory = false

      macos-option-as-alt = true

      # Keybindings
      keybind = global:option+space=toggle_quick_terminal
    '';
  };
  xdg.configFile."ghostty/themes/dlond.ghostty" = {
    source = ./themes/dlond.ghostty;
  };

  sops.age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
}
