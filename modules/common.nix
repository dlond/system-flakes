{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    # CLI / editor stack
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
    gnupg
    tree
    ruff

    go
    rustup
    nodejs_20
    nixpkgs-fmt
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    xclip
  ];
}
