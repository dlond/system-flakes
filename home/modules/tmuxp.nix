let
  # Shared nvim session name for consistent editor state across windows
  sharedNvimSession = "dev-nvim-shared";
  
  devFull = {
    session_name = "dev";
    windows = [
      {
        window_name = "editor";
        layout = "0171,215x60,0,0[215x44,0,0{139x44,0,0,0,75x44,140,0,2},215x15,0,45,1]";
        panes = [
          {
            shell_command_before = [
              # Create shared nvim session with error handling
              "tmux has-session -t \"${sharedNvimSession}\" 2>/dev/null || tmux new-session -d -s \"${sharedNvimSession}\" nvim ."
            ];
            shell_command = [
              # Attach to shared nvim session with fallback
              "TMUX= tmux attach-session -t \"${sharedNvimSession}\" || nvim ."
            ];
          }
          {
            shell_command = [
              "claude"
            ];
          }
          {
            # Bottom pane - just a shell, no need to launch zsh explicitly
            shell_command = [];
          }
        ];
      }
      {
        window_name = "side-by-side";
        layout = "e5e0,215x60,0,0{107x60,0,0,3,107x60,108,0,4}";
        panes = [
          {
            shell_command_before = [
              # Create shared nvim session with error handling
              "tmux has-session -t \"${sharedNvimSession}\" 2>/dev/null || tmux new-session -d -s \"${sharedNvimSession}\" nvim ."
            ];
            shell_command = [
              # Attach to shared nvim session with fallback
              "TMUX= tmux attach-session -t \"${sharedNvimSession}\" || nvim ."
            ];
          }
          {
            shell_command = ["tmux ls"];
          }
        ];
      }
    ];
  };
in {
  xdg.configFile."tmuxp/dev-full.json".text = builtins.toJSON devFull;
}
