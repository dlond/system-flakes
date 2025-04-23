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
  ];

  # Enable Zsh management via Home Manager
  programs.zsh = {
    enable = true;
	dotzshrc.source = ../../files/zshrc;
  };

  # Enable and configure Oh My Posh
  programs.oh-my-posh = {
    enable = true;
    # This automatically enables integration for shells enabled via HM (like Zsh above).
    # It will ensure the correct 'oh-my-posh init zsh' command runs using the
    # HM-managed package path.

    # Theme
    theme = ../../files/omp/my_catppuccin.toml;
  };

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
  # Other configs
}
