{ config, pkgs, lib, ... }:

{
  users.users.dlond = {
    name = "dlond";
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };
}

