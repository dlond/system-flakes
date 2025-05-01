{ config, pkgs, lib, ... }:

{
  # This file is for configuration options common to 'dlond'
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
    };
  };

  xdg.configFile."bat/themes" = {
    source = ./files/bat/themes;
    recursive = true;
  };
}
