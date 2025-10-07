{
  nixpkgs,
  rust-overlay,
  overlays ? [],
  config ? {allowUnfree = true;},
}: system: let
  nodeOverlay = final: prev: {
    nodejs_22 = prev.nodejs_22.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });
  };
in
  import nixpkgs {
    inherit system config;
    overlays =
      overlays
      ++ [
        rust-overlay.overlays.default
        nodeOverlay
      ];
  }
