{ config, lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports =
    [ ../../../modules/home/base.nix ]
    ++ (if isDarwin then [ ./mac.nix ] else [])
    ++ (if isLinux then [ ./linux.nix ] else []);
}

