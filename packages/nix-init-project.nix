{ pkgs }:

pkgs.writeShellScriptBin "nix-init-project" ''
  ${builtins.readFile ../scripts/nix-init-project}
''