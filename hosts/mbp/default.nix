{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  shared = import ../../lib/shared.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
in {
  environment.systemPackages =
    shared.sharedCliTools
    ++ [pkgs.raycast];

  nix.settings.experimental-features = "nix-command flakes";

  system = {
    primaryUser = username;
    stateVersion = 6;
    defaults = {
      dock = {
        autohide = true;
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

  security.pam.services.sudo_local.touchIdAuth = true;
  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  nix-homebrew = {
    enable = true;
    user = username;
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
      "ollama"
    ];
    casks = [
      "1password"
      "1password-cli"
      "anythingllm"
      "claude"
      "claude-code"
      "ghostty"
      "mullvad-vpn"
      "steam"
      "tor-browser"
      "vlc"
    ];
  };
}
