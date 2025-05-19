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

  environment.systemPackages = 
    sharedCliPkgs ++ (with pkgs; [
      raycast
    ]);

  nix.settings.experimental-features = "nix-command flakes";

  home-manager.users.dlond = import ../../home/dlond.nix;

  system = {
    primaryUser = "dlond";
    defaults = {
      dock = {
        autohide = false;
        show-recents = false;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
	FXRemoveOldTrashItems = true;
	FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
      };
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.dlond = {
    home = "/Users/dlond";
    shell = pkgs.zsh;
  };

  system.stateVersion = 6;
}
