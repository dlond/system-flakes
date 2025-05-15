{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    gh
    neovim
    tmux
    mosh
    fzf
    zoxide
    bat
    ripgrep
    fd
    oh-my-posh
    gnupg
    tree
    ruff

    go
    rustup
    nodejs
    nixpkgs-fmt
  ];

  programs = {
    zsh.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home.stateVersio = "24.05";
}
