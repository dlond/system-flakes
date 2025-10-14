{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";

    defaultOptions = [
      "--ansi"
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-a:select-all,ctrl-d:deselect-all"
      "--bind=ctrl-n:down,ctrl-p:up"
      "--bind=tab:down"
      "--bind=ctrl-y:accept,enter:accept"
      "--border"
      "--cycle"
      "--height=40%"
      "--info=inline"
      "--layout=reverse"
      "--marker=✓"
      "--multi"
      "--pointer=▶"
      "--prompt=❯"
      "--smart-case"
    ];

    # Use separate options for complex commands to avoid escaping issues
    changeDirWidgetOptions = [
      "--preview='eza --color=always --tree --level=2 --icons {}'"
      "--preview-window=right:50%"
    ];

    fileWidgetOptions = [
      "--preview='bat --color=always --style=numbers,header {}'"
      "--preview-window=right:50%"
    ];

    historyWidgetOptions = [
      "--height=40%"
      "--border"
      "--preview=echo {}"
      "--preview-window=down:3:wrap"
    ];
  };
}
