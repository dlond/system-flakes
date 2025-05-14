{ lib, pkgs, inputs, ... }:
{
    # imports = (import ../../lib/import-modules.nix { inherit lib; }) { dir = ./programs; };
    imports = (lib.importModules { dir = ./programs; inherit lib pkgs inputs; });
}
