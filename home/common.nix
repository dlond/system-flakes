{ config, pkgs, lib, ... }:

{
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
    config.global.hide_env_diff = true;
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

  xdg.configFile."direnv/direnv.toml" = {
    text = ''
      # This is the content for ~/.config/direnv/direnv.toml
      [global]
      warn_timeout = 0
      hide_env_diff = true
      # Add any other global direnv settings here if needed
    '';
    # source = ./files/direnv/direnv.toml; if it gets big
  };
}
