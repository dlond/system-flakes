{ pkgs, inputs, ... }: {
  imports = [
    ../../modules/common.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  users.users.dlond = {
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # nix-darwin-managed global Nix Settings
  nix.settings = {
    build-users-group = "nixbld";
    experimental-features = "nix-command flakes";
    ssl-cert-file = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
  };

  home-manager.users.dlond = import ../../home/dlond.nix;

  system.stateVersion = 6;
}

