{ config, pkgs, ... }:

{
  options = {};

  config = {
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };
}
