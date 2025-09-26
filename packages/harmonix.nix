{ pkgs }:

pkgs.writeShellScriptBin "harmonix" ''
  ${builtins.readFile ../scripts/harmonix}
''