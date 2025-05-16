{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Core utilities
    bat
    curl
    gnugrep
    gnupg
    gnused
    tree
    unzip
    wget

    # Dev tools
    direnv
    fd
    fzf
    gh
    git
    htop
    mosh
    neovim
    ripgrep
    tmux
    zoxide

    # Prompt
    oh-my-posh

    # Formatters / linters
    alejandra
    ruff
    stylua

    # LSPs
    # clangd
    lua-language-server
    nil
    # pywrite
    
    # Debuggers
    delve

    # Misc
    go
    rustup
    nodejs
    nixpkgs-fmt
  ];

  home.file.".config/nvim/init.lua".source = inputs.nvim-config + "/init.lua";
  home.file.".config/nvim/lua".source = inputs.nvim-config + "/lua";

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  imports = [
  ];
    

  home.stateVersion = "24.05";
}
