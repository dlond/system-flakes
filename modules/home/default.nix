{ pkgs, ... }:
{
  imports = [
    ./common.nix
  ];

  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";
}
