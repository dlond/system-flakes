{
  nixpkgs,
  overlays ? [],
  config ? {allowUnfree = true;},
}: system:
import nixpkgs {
  inherit system overlays config;
}
