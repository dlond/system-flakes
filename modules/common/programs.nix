{ config, pkgs, ... }:

{
  options = {};

  config = {
    programs.direnv = {
      enable = true;
      # enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
    };

    # Add other program configurations here, e.g.
    # programs.fish.enable = true
  };
}
