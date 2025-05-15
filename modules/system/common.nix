{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    wget
    vim
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
