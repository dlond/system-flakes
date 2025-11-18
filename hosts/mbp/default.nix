{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  packages = import ../../lib/packages.nix {inherit pkgs;};
in {
  environment.systemPackages = with packages.system;
    essential
    ++ security
    ++ apps
    ++ development.cpp
    ++ development.python
    ++ development.misc;

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

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age = {
      keyFile = "/Users/${username}/Library/Application Support/sops/age/keys.txt";
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];
    secrets = {
      github_token = {
        neededForUsers = false;
      };
    };
  };

  nix.settings = {
    access-tokens = ["github.com=${config.sops.secrets.github_token.path}"];
  };

  # Configure PAM for Touch ID with tmux support
  # The pam-reattach module moves sudo to the GUI session for Touch ID access
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
    auth       sufficient     pam_tid.so
  '';

  fonts.packages = packages.system.fonts;

  nix-homebrew = {
    enable = true;
    user = username;
  };

  homebrew = with packages.system.homebrew; {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    inherit taps brews casks;
  };
}
