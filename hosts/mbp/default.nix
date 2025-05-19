{
  pkgs,
  inputs,
  sharedCliPkgs,
  ...
}: {
  imports = [
    ../../modules/cli-tools.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  environment.systemPackages = sharedCliPkgs;

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
