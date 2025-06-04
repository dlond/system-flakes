{
  pkgs,
  lib,
  inputs,
  username,
  nvim-config,
  catppuccin-bat,
  home-manager,
  nix-homebrew,
  ...
}: let
  shared = import ../../lib/shared.nix {inherit pkgs lib;};
in {
  environment.systemPackages =
    shared.sharedCliTools
    ++ [pkgs.raycast];

  imports = [
    ./modules/system/security/killswitch.nix
    home-manager.darwinModules.home-manager
    nix-homebrew.darwinModules.nix-homebrew
  ];

  modules.system.security.killswitch.enable = false;

  system = {
    primaryUser = "dlond";
    stateVersion = 6;
    defaults = {
      dock = {
        autohide = false;
        show-recents = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        FXRemoveOldTrashItems = true;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
      };
    };
  };

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  nix-homebrew = {
    enable = true;
    user = "dlond";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [];
    brews = [
      "mas"
    ];
    casks = [
      "1password"
      "1password-cli"
      "ghostty"
      "steam"
      "tor-browser"
      "vlc"
    ];
  };

  nix.settings.experimental-features = "nix-command flakes";

  home-manager.extraSpecialArgs = {inherit inputs username nvim-config catppuccin-bat;};
  home-manager.users.dlond = import ../../home/dlond/default.nix;

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.dlond = {
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };
}
