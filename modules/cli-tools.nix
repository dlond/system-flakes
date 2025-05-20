{pkgs, ...}: {
  _module.args.sharedCliPkgs = with pkgs;
    [
      alejandra
      bat
      clang-tools
      fd
      fzf
      gh
      git
      gnupg
      go
      lua-language-server
      mosh
      neovim
      nixd
      nodejs_20
      pyright
      ripgrep
      ruff
      rustup
      stylua
      tmux
      tree
      zoxide
      zsh-fzf-tab
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      xclip
    ];
}
