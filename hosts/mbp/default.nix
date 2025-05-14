{ inputs, pkgs, lib, ... }:

{
  # Import reusable modules
  imports = [
    ../../modules/common/global.nix
    ../../modules/darwin/base.nix
    ../../modules/darwin/fonts.nix
    ../../modules/darwin/homebrew.nix

    # Add the external modules here:
    inputs.nix-homebrew.darwinModules.nix-homebrew
    # inputs.mac-app-util.darwinModules.default

    # Add other custom modules as needed, e.g.:
    # ../../modules/darwin/gui-apps.nix # If you separate GUI apps
  ];

  # Specific settings for this host 'mbp'
  networking.hostName = "mbp";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set Git commit hash for darwin-version
  # system.configurationRevision comes from the base module now.

  # Any other 'mbp' specific overrides or configurations go here
  environment.etc."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
  '';
}
