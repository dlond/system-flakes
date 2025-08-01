{
  pkgs,
  lib,
  ...
}: {
  sharedCliTools = with pkgs;
    [
      age
      alejandra
      bash
      bat
      brave
      clang-tools
      cmake-language-server
      curl
      delta
      eza
      fd
      firefox
      fzf
      gh
      git
      git-filter-repo
      gnupg
      go
      lua-language-server
      lua5_1
      luarocks
      mosh
      neovim
      nixd
      nodejs_20
      obsidian
      pyright
      python3Packages.debugpy
      ripgrep
      ruff
      rustup
      sops
      stylua
      texlab
      tmux
      tmuxp
      tree
      tree-sitter
      wget
      yq
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
