{ config, lib, pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  xdg.configFile.direnv/direnv.toml = {
    text = ''
      [global]
      warn_timeout = 0
      hide_env_diff = true
    '';
  };
}

