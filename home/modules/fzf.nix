{
  config,
  lib,
  pkgs,
  packages,
  ...
}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type f";
    defaultOptions = [
      "--ansi"
      "--bind='ctrl-n:down,ctrl-p:up,tab:down,ctrl-e:execute-silent(echo {+} | ${packages.system.clipboardCommand})+abort,ctrl-w:become(nvim {+}),ctrl-y:accept,enter:accept,shift-tab:toggle+down'"
      "--border"
      "--color=16"
      "--color=fg+:#ffffff,bg+:#262626,hl+:#ff5f5f"
      "--color=fg:#d0d0d0,bg:#1c1c1c,hl:#d75f5f"
      "--color=info:#af87ff,prompt:#5f87ff,pointer:#ffaf00"
      "--color=marker:#ffff00,spinner:#5f87ff,header:#87af5f"
      "--cycle"
      "--height=40%"
      "--info=inline"
      "--layout=reverse"
      "--marker=✓"
      "--multi"
      "--pointer=▶"
      "--preview-window=right:50%"
      "--preview='if [ -d {} ]; then eza {}; else bat {}; fi'"
      "--prompt=❯"
      "--smart-case"
    ];

    # Use separate options for complex commands to avoid escaping issues
    changeDirWidgetOptions = [
      "--preview=eza {}"
    ];

    fileWidgetOptions = [
      "--preview=bat {}"
    ];

    historyWidgetOptions = [
      "--height=40%"
      "--layout=reverse" 
      "--border"
      "--preview=echo {}"
      "--preview-window=right:50%:wrap"
    ];
  };
}
