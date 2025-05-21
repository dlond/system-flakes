{
  pkgs,
  inputs,
  sharedCliPkgs,
  nvim-config,
  ...
}: {
  imports = [
    ../../modules/cli-tools.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  environment.systemPackages =
    sharedCliPkgs
    ++ (with pkgs; [
      raycast
    ]);

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

  home-manager.extraSpecialArgs = {inherit nvim-config;};
  home-manager.users.dlond = import ../../home/dlond.nix;

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
        AppleShowAllFiles = true;
        FXRemoveOldTrashItems = true;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
      };
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.dlond = {
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };
}
