{pkgs, ...}:
let
  # Create a shell script that generates tmuxp configs dynamically
  tmuxpProjectScript = pkgs.writeShellScriptBin "tmuxp-project" ''
    # Get the project name from the current directory
    PROJECT_DIR=$(pwd)
    
    # Extract project name from path
    if [[ "$PROJECT_DIR" =~ .*/dev/projects/([^/]+) ]]; then
      PROJECT_NAME="''${BASH_REMATCH[1]}"
    elif [[ "$PROJECT_DIR" =~ .*/dev/worktrees/([^/]+)/([^/]+) ]]; then
      # For worktrees, use the project name (first part after worktrees)
      PROJECT_NAME="''${BASH_REMATCH[1]}"
    else
      # Fallback to basename of current directory
      PROJECT_NAME=$(basename "$PROJECT_DIR")
    fi
    
    # Create session and shared nvim session names
    SESSION_NAME="$PROJECT_NAME"
    SHARED_NVIM_SESSION="''${PROJECT_NAME}-nvim-shared"
    
    # Generate the tmuxp config dynamically
    cat > /tmp/tmuxp-''${PROJECT_NAME}.json <<EOF
    {
      "session_name": "$SESSION_NAME",
      "windows": [
        {
          "window_name": "editor",
          "layout": "0171,215x60,0,0[215x44,0,0{139x44,0,0,0,75x44,140,0,2},215x15,0,45,1]",
          "panes": [
            {
              "shell_command_before": [
                "tmux has-session -t \"$SHARED_NVIM_SESSION\" 2>/dev/null || tmux new-session -d -s \"$SHARED_NVIM_SESSION\" nvim ."
              ],
              "shell_command": [
                "TMUX= tmux attach-session -t \"$SHARED_NVIM_SESSION\" || nvim ."
              ]
            },
            {
              "shell_command": [
                "claude"
              ]
            },
            {
              "shell_command": []
            }
          ]
        },
        {
          "window_name": "side-by-side",
          "layout": "e5e0,215x60,0,0{107x60,0,0,3,107x60,108,0,4}",
          "panes": [
            {
              "shell_command_before": [
                "tmux has-session -t \"$SHARED_NVIM_SESSION\" 2>/dev/null || tmux new-session -d -s \"$SHARED_NVIM_SESSION\" nvim ."
              ],
              "shell_command": [
                "TMUX= tmux attach-session -t \"$SHARED_NVIM_SESSION\" || nvim ."
              ]
            },
            {
              "shell_command": ["tmux ls"]
            }
          ]
        }
      ]
    }
    EOF
    
    # Load the generated config
    tmuxp load /tmp/tmuxp-''${PROJECT_NAME}.json
  '';
  
  # Keep the static dev-full.json for backward compatibility
  # But it will use "dev" as session name
  devFull = {
    session_name = "dev";
    windows = [
      {
        window_name = "editor";
        layout = "0171,215x60,0,0[215x44,0,0{139x44,0,0,0,75x44,140,0,2},215x15,0,45,1]";
        panes = [
          {
            shell_command_before = [
              "tmux has-session -t \"dev-nvim-shared\" 2>/dev/null || tmux new-session -d -s \"dev-nvim-shared\" nvim ."
            ];
            shell_command = [
              "TMUX= tmux attach-session -t \"dev-nvim-shared\" || nvim ."
            ];
          }
          {
            shell_command = [
              "claude"
            ];
          }
          {
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
              "tmux has-session -t \"dev-nvim-shared\" 2>/dev/null || tmux new-session -d -s \"dev-nvim-shared\" nvim ."
            ];
            shell_command = [
              "TMUX= tmux attach-session -t \"dev-nvim-shared\" || nvim ."
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
  # Install the tmuxp-project script
  home.packages = [ tmuxpProjectScript ];
  
  # Keep backward compatibility with dev-full.json
  xdg.configFile."tmuxp/dev-full.json".text = builtins.toJSON devFull;
}
