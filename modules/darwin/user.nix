{ pkgs, ... }:

# This defines the user account — needed for `home-manager.users.dlond`
{
  users.users.dlond = {
    name = "dlond";
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };
}

