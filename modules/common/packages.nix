# Defines system-wide packages
{ config, pkgs, lib, ... }:

{
  options = {};

  config = {
    # List packages installed system-wide
    # CONSIDER: Many of these are user tools and might be better managed
    #           via Home Manager (home.packages) for better separation.
    environment.systemPackages = with pkgs; [
      # CLI Tools
      git
      gh
      neovim
      tmux
      stow
      fzf
      zoxide
      bat
      ripgrep
      fd
      wget
      tree
      oh-my-posh

      # Development Languages/Tools
      go
      rustup
      nodejs

      # Security/Privacy
      gnupg
      tor

      # GUI apps (Installed via Nixpkgs - could be in a separate darwin/gui-apps.nix)
      # Or potentially managed via homebrew casks if prefered
      raycast
      whatsapp-for-mac
      ollama
    ];
  };
}
