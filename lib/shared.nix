{
  pkgs,
  lib,
  ...
}: let
  harmonix = pkgs.callPackage ../packages/harmonix.nix {};
in {
  sharedCliTools = with pkgs;
    [
      age
      alejandra
      bash
      bat
      brave
      chatgpt
      claude-code
      curl
      delta
      discord-ptb
      eza
      fd
      firefox
      fswatch
      fzf
      gh
      git
      git-filter-repo
      glow
      gnupg
      go
      lua5_1
      luarocks
      mosh
      neovim
      harmonix
      nodejs_20
      obsidian
      ripgrep
      rustup
      shellcheck
      sops
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

  # Platform-specific clipboard command
  # Used by fzf, tmux, and zsh configurations
  clipboardCommand =
    if pkgs.stdenv.isDarwin
    then "pbcopy"
    else if pkgs.stdenv.isLinux
    then "xclip -selection clipboard"
    else "clip"; # Fallback for Windows/WSL
}
