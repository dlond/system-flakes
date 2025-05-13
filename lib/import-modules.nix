{ lib }:

dir:
  builtins.attrValues (
    builtins.mapAttrs (_: path: import (dir + "/${path}"))
      (lib.filterAttrs (_: type: type == "regular") (builtins.readDir dir))
  )

