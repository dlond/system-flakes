{ config, lib, pkgs, ... }:
{
  imports = 
    let
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
     in
        [ ../../../modules/home/base.nix ]
        ++ (if isDarwin then [ ./mac.nix ] else [])
        ++ (if isLinux then [ ./linux.nix ] else []);
}

