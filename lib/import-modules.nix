{ lib }: 
  { dir }:
    map (f: dir + "/${f}") (
      lib.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames (builtins.readDir dir))
    )
