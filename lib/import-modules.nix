dir: builtins.attrValues (
  builtins.mapAttrs (_: path: import (dir + "/${path}"))
    (builtins.removeAttrs (builtins.readDir dir) [".."])
)
