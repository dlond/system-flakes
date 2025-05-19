{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../modules/common.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  users.users.dlond = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  home-manager.users.dlond = import ../../home/dlond.nix;

  system.stateVersion = "24.05";
}
