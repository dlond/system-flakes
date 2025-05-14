{ config, lib, pkgs, inputs, ... }:

# let
#   # Get the primary username configured for the host
#   # This assumes you define users.users.username in your host config
#   # or a common users module. Fallback needed if not defined.
#   primaryUser = lib.mkDefault (builtins.head (builtins.attrNames config.users.users));
# in
{
  options = {};

  config = {
    # Configure the nix-homebrew module itself
    # This block gets merged with the one potentially defined in host config
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      # user = primaryUser;
    };

    # Configure Homebrew itself via nix-darwin's homebrew options
    homebrew = {
      enable = true;
      taps = [];
      brews = [
        # 'mas'
      ];
      casks = [
        "ghostty"
        "1password"
        "1password-cli"
        "vlc"
        "balenaetcher"
      ];
      # masApps = { ... }; # Keep your masApps definition here if using 'mas' brew

      # Activation settings
      onActivation.cleanup = "uninstall";
      onActivation.autoUpdate = true;
      onActivation.upgrade = true;
    };
  };
}
