{ config, lib, pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config.theme = Catppuccin Mocha;
  };

  xdg.configFile."bat/themes" = {
    source = ./files/themes;
    recursive = true;
  };
}

