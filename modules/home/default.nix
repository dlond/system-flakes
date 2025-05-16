{ pkgs, inputs, ... }:
{
  imports = [
    (import ./common.nix { inherit pkgs inputs; })
  ];

  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";
}
