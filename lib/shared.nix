{
  pkgs,
  lib,
  ...
}: {
  sharedCliTools = with pkgs;
    [
      alejandra
      bash
      bat
      clang-tools
      cmake-language-server
      curl
      eza
      fd
      fzf
      gh
      git
      gnupg
      go
      lua-language-server
      lua5_1
      luarocks
      mosh
      neovim
      nixd
      nodejs_20
      pyright
      python3Packages.debugpy
      ripgrep
      ruff
      rustup
      stylua
      texlab
      tmux
      tree
      tree-sitter
      wget
      zoxide
      zsh-fzf-tab
      zsh-vi-mode
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      xclip
    ];

  forDarwin = lib.mkIf pkgs.stdenv.isDarwin;
  forLinux = lib.mkIf pkgs.stdenv.isLinux;
}
