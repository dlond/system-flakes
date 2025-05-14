{ config, lib, pkgs, ... }:

{
  options = {}; # Define custom options here if needed
  
  config = {
    # Allow unfree packages globally (adjust per-host if needed)
    nixpkgs.config.allowUnfree = true;
  };
}
