{
  config,
  packages,
  pkgs,
  username,
  ...
}: {
  environment = {
    systemPackages =
      (with packages.system;
        utils
        ++ security
        ++ apps
        ++ development.cpp
        ++ development.python
        ++ development.ocaml
        ++ development.rust
        ++ development.misc
        ++ development.neovim)
      ++ [
        pkgs.pam-reattach # macOS PAM module for Touch ID with tmux/sudo
      ];
  };

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
      keyFile = "/var/lib/sops/age/key.txt";
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
    access-tokens = ["api.github.com=${config.sops.secrets.github_token.path}"];
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
