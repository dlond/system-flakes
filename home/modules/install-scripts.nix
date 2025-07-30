{
  config,
  lib,
  pkgs,
  ...
}: let
  # fallback path if not overridden
  defaultScriptsRoot = ../../users/dlond/scripts;
  scriptsRoot = builtins.toPath (config.my.scripts.root or defaultScriptsRoot);

  # Recursively collect files from all subdirectories
  getScripts = path: let
    entries = builtins.readDir path;
  in
    lib.concatMapAttrs (
      name: type: let
        fullPath = "${path}/${name}";
      in
        if type == "directory"
        then getScripts fullPath
        else if lib.hasSuffix ".zsh" name || lib.hasSuffix ".sh" name
        then let
          relative = lib.removePrefix (toString scriptsRoot + "/") (toString fullPath);
        in {
          "${relative}" = fullPath;
        }
        else {}
    )
    entries;

  scripts = getScripts scriptsRoot;

  zshInitLines =
    lib.pipe (lib.attrNames scripts)
    [
      (builtins.filter (p: lib.hasSuffix ".zsh" p))
      (builtins.map (p: "source ~/.local/scripts/" + p))
      (builtins.concatStringsSep "\n")
    ];
in {
  options.my.scripts = {
    enable = lib.mkEnableOption "Install user scripts";
    root = lib.mkOption {
      type = lib.types.path;
      default = defaultScriptsRoot;
      description = "Path to the root directory containing user scripts.";
    };
  };

  config = lib.mkIf config.my.scripts.enable {
    home.file =
      lib.mapAttrs (relPath: src: {
        source = src;
        target = ".local/scripts/${relPath}";
        executable = true;
      })
      scripts;

    programs.zsh.initExtra = zshInitLines;
  };
}
