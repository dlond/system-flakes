{ lib, ... }:

{
    imports = (import ../../lib/import-modules.nix { inherit lib; }) { dir = ./programs; };
}
