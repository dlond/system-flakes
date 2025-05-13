{ inputs, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  # Import common settings and OS-specific files
  imports =
    [ ../../common.nix ]
    ++ (if isDarwin then [ ./mac.nix ] else [])
    ++ (if isLinux then [ ./linux.nix ] else []);

} # End of HM configuration block

