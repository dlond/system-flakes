{ config, lib, pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin-mocha";
      style = "full";
      pager = "less -FR";
    };
    themes = {
      "Catppuccin-mocha" = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };
        file = "./themes/Catppuccin-mocha.tmTheme";
      };
    };
  };
}

