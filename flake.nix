{
  description = "Minimal nix-darwin + Home Manager setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Optionally, add nix-darwin/home-manager as overlays for Mac, or nixosConfigurations for Linux
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";  # or x86_64-darwin for Intel Macs
      username = "dlond";         # change to your username
    in
    {
      darwinConfigurations.mbp = darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./hosts/mbp/default.nix
        ];
      };
      homeConfigurations."${username}@mbp" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [
          ./home/dlond.nix
        ];
        extraSpecialArgs = { inherit username; };
      };
    };
}

