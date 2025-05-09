# Defines system-wide packages
{ config, pkgs, lib, ... }:

{
  options = {};

  config = {
    # List packages installed system-wide
    # CONSIDER: Many of these are user tools and might be better managed
    #           via Home Manager (home.packages) for better separation.
    environment.systemPackages = with pkgs; [
      # Basic Utilities
      curl
      wget

      # Services / Daemons / GUI Apps
      tor
      raycast
      whatsapp-for-mac
      ollama
    ];
  };
}
