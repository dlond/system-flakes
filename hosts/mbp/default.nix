{ inputs, pkgs, lib, ... }:

{
  # Import reusable modules
  imports = [
    ../../modules/common/global.nix
    ../../modules/common/packages.nix
    ../../modules/common/programs.nix
    ../../modules/darwin/base.nix
    ../../modules/darwin/fonts.nix
    ../../modules/darwin/homebrew.nix

    # Add the external modules here:
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.mac-app-util.darwinModules.default

    # Add other custom modules as needed, e.g.:
    # ../../modules/darwin/gui-apps.nix # If you separate GUI apps
  ];

  # Specific settings for this host 'mbp'
  networking.hostName = "mbp";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set Git commit hash for darwin-version
  # system.configurationRevision comes from the base module now.

  # User account settings (can also be in a common/users.nix module)
  users.users.dlond = {
    name = "dlond";
    home = "/Users/dlond/";
    shell = "${pkgs.zsh}/bin/zsh";
    # Add groups, shell, etc. if needed
  };

  # Any other 'mbp' specific overrides or configurations go here
}
