{pkgs, ...}: {
  _module.args.sharedCliPkgs = with pkgs;
    [
      alejandra
      bat
      clang-tools
      cmake-language-server
      eza
      fd
      fzf
      gh
      git
      gnupg
      go
      lua5_1
      lua-language-server
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
      zoxide
      zsh-fzf-tab
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      xclip
    ];
}
