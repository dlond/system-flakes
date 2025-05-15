{ lib, pkgs, inputs, ... }:

{
    # imports = (lib.importModules { dir = ./programs; inherit lib pkgs inputs; });
    imports = [
        ./programs/bat.nix
        ./programs/fzf.nix
        ./programs/direnv.nix
        ./programs/oh-my-posh.nix
        ./programs/zoxide.nix
    ]; 
}
