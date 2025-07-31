{
  config,
  lib,
  pkgs,
  ...
}: let
  tmuxpDefault = {
    session_name = "default";
    windows = [
      {
        window_name = "dev";
        layout = "main-horizontal";
        panes = [
          {shell_command = ["nvim"];}
          {shell_command = ["claude"];}
        ];
      }
    ];
  };
in {
  xdg.configFile."tmuxp/default.json".text = builtins.toJSON tmuxpDefault;
}
