{pkgs, ...}: {
  _module.args.sharedCliPkgs = with pkgs;
    [
      alejandra
      bat
      fd
      fzf
      gh
      git
      gnupg
      go
      mosh
      neovim
      nodejs_20
      ripgrep
      ruff
      rustup
      tmux
      tree
      zoxide
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      xclip
    ];
}
