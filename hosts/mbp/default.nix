{ pkgs, ... }:
{
  system.defaults = {
    dock.autohide = true;
  };

  networking.hostName = "mbp";

  users.users.dlond = {
    home = "/Users/dlond";
  };

  system.stateVersion = 6;
}

