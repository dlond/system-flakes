{ lib, pkgs, inputs, ... }:
{
    imports = (lib.importModules { dir = ./programs; inherit lib pkgs inputs; });
}
