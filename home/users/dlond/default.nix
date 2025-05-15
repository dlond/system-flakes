{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../modules/home/base.nix
    ./mac.nix
  ];

  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";
  home.stateVersion = "24.05";
}

