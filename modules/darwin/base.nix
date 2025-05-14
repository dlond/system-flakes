{ config, lib, pkgs, inputs, ... }: # Access inputs via specialArgs

{
  options = {};

  config = {
    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Use touchID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;

    # Set Git commit hash for darwin-version.
    # Passed via specialArgs from flake.nix -> darwinSystem
    system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    system.stateVersion = 6; # Keep this value consistent with your original setup

    # Potentially other base settings like time zone, localization etc.
    # time.timeZone = "Pacific/Auckland";
  };
}
