{ lib }: dir:
  map (f: dir + (/ + f)) (
    builtins.attrNames (
      lib.filterAttrs
        (name: type: type == regular && lib.hasSuffix .nix name)
        (builtins.readDir dir)
    )
  );

