{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--ansi"
      "--bind=ctrl-n:down,ctrl-p:up,ctrl-y:accept,tab:down,shift-tab:toggle+down,enter:accept"
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
      "--preview='bat --style=numbers --color=always {}'"
      "--prompt=❯ "
      "--smart-case"
    ];
  };
}
