{ pkgs, ... }:
{
  system.defaults = {
    dock.authide = true;
  };

  networking.hostName = "mbp";
  users.users.dlond = {
    home = "/Users/dlond";
  };

  services.nix-daemon.enable = true;
}

