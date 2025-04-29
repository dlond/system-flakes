{ pkgs, config, lib, system, ... }:

{
  imports = [
    ../../common.nix
    ./mac.nix # (if pkgs.stdenv.isDarwin then ./mac.nix else ./linux.nix)
  ];

  # Home Manager needs a state version. Put it in the main user entry point.
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # CLI Tools / User Apps
    git
    gh
    neovim
    tmux
    screen
    fzf
    zoxide
    bat
    ripgrep
    fd
    oh-my-posh
    gnupg

    # Development Languages/Tools (User/Nvim Deps)
    go
    rustup
    nodejs
    nixpkgs-fmt
  ];

  xdg.configFile."omp/my_catppuccin.toml" = {
    source = ../../files/omp/my_catppuccin.toml;
  };

  # Enable Zsh management via Home Manager
  programs.zsh = {
    enable = true;

    initContent = ''
      # Initialize Oh My Posh
      if command -v oh-my-posh > /dev/null; then
        eval "$(oh-my-posh init zsh --config '${config.xdg.configHome}/omp/my_catppuccin.toml')"
      fi
    '';
  };

  home.file.".zshrc" = {
    source = ../../files/zshrc;
  };

  # Enable and configure Oh My Posh
  # programs.oh-my-posh = {
  #   enable = true;
  #   theme = ../../files/omp/my_catppuccin.toml;
  # };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."nvim" = {
    # Source points to the nvim config dir WITHIN your nix config repo
    # Path is relative to this nxi file
    source = ../../files/.config/nvim;
    recursive = true;
  };

  programs.git = {
    enable = true;
    userName = "dlond";
    userEmail = "dlond@me.com";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDBuv1nRNSziTjf2UuGhFk7ftnDXOuMfew5FMeINM66";
      format = "ssh";
      signer = if pkgs.stdenv.isDarwin then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" else "<linux-helper>";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
    };

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      color.ui = true;
      push.default = "current";
    };
  };
  # Other configs
}
