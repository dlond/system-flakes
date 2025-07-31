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
          {shell_command = ["llm"];}
        ];
      }
    ];
  };
in {
  xdg.configFile."tmuxp/default.yaml".text = builtins.toJSON tmuxpDefault;
}
