{ pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports =
    [ ../../common.nix ]
    ++ (if isDarwin then [ ./mac.nix ] else [])
    ++ (if isLinux then [ ./linux.nix ] else []);
}

