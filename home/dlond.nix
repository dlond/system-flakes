{ pkgs, ... }: {
  home.username = "dlond";
  home.homeDirectory = "/Users/dlond";
  home.stateVersion = "24.05";

  programs.zsh.enable = true;

  programs.neovim.enable = true;

  # You can add other programs here
}

